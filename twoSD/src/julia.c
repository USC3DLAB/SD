#include "twoSD.h"
#include <inttypes.h>
#include <assert.h>

extern configType config;
extern string outputDir;
extern ENVptr env;

void check_env()
{
	if (env == NULL)
	{
		errMsg("Julia", "check_env", "env is empty.", 0);
	}
}

int readConfig_jl(const char *config_path, const char* output_path) {
	FILE 	*fptr;
	char	line[2*BLOCKSIZE], comment[2*BLOCKSIZE];
	int 	status, r2 = 1, maxReps = 30;

    fptr = fopen(config_path, "r");
	if ( fptr == NULL ) {
		printf("DEBUG: Config file search path: %s", config_path);
		errMsg("read", "readConfig", "failed to open configuration file", 0);
		return 1;
	}

	/* TODO: wrap this */
	const size_t MAX_PATH_LEN = 1024;
	outputDir = malloc(sizeof(char) * MAX_PATH_LEN);
	strcpy(outputDir, output_path);

	config.RUN_SEED = (long long *) arr_alloc(maxReps+1, long long);
	config.EVAL_SEED = (long long *) arr_alloc(maxReps+1, long long);
	config.NUM_REPS = 0;

	while ((status = (fscanf(fptr, "%s", line) != EOF))) {
		if (!(strcmp(line, "RUN_SEED"))) {
			fscanf(fptr, "%" PRId64, &config.RUN_SEED[config.NUM_REPS+1]);
			config.NUM_REPS++;
			if ( config.NUM_REPS > maxReps ) {
				config.RUN_SEED = (long long *) mem_realloc(config.RUN_SEED, (2*maxReps+1)*sizeof(long long));
				maxReps *= 2;
			}
		}
		else if (!(strcmp(line, "TOLERANCE")))
			fscanf(fptr, "%lf", &config.TOLERANCE);
		else if (!(strcmp(line, "MIN_ITER")))
			fscanf(fptr, "%d", &config.MIN_ITER);
		else if (!(strcmp(line, "MAX_ITER")))
			fscanf(fptr, "%d", &config.MAX_ITER);
		else if (!(strcmp(line, "MASTER_TYPE")))
			fscanf(fptr, "%d", &config.MASTER_TYPE);
		else if (!(strcmp(line, "CUT_MULT")))
			fscanf(fptr, "%d", &config.CUT_MULT);
		else if (!(strcmp(line, "TAU")))
			fscanf(fptr, "%d", &config.TAU);
		else if (!(strcmp(line, "MIN_QUAD_SCALAR")))
			fscanf(fptr, "%lf", &config.MIN_QUAD_SCALAR);
		else if (!(strcmp(line, "MAX_QUAD_SCALAR")))
			fscanf(fptr, "%lf", &config.MAX_QUAD_SCALAR);
		else if (!(strcmp(line, "R1")))
			fscanf(fptr, "%lf", &config.R1);
		else if (!(strcmp(line, "R2")))
			fscanf(fptr, "%lf", &config.R2);
		else if (!(strcmp(line, "R3")))
			fscanf(fptr, "%lf", &config.R3);
		else if (!(strcmp(line, "DUAL_STABILITY")))
			fscanf(fptr, "%d", &config.DUAL_STABILITY);
		else if (!(strcmp(line, "PI_EVAL_START")))
			fscanf(fptr, "%d", &config.PI_EVAL_START);
		else if (!(strcmp(line, "PI_CYCLE")))
			fscanf(fptr, "%d", &config.PI_CYCLE);
		else if (!(strcmp(line, "PERCENT_PASS")))
			fscanf(fptr, "%lf", &config.PERCENT_PASS);
		else if (!(strcmp(line, "SCAN_LEN")))
			fscanf(fptr, "%d", &config.SCAN_LEN);
		else if (!(strcmp(line, "EVAL_FLAG")))
			fscanf(fptr, "%d", &config.EVAL_FLAG);
		else if (!(strcmp(line, "EVAL_SEED"))) {
			fscanf(fptr, "%" PRId64, &config.EVAL_SEED[r2++]);
			if ( r2 > maxReps ) {
				config.RUN_SEED = (long long *) mem_realloc(config.RUN_SEED, (2*maxReps+1)*sizeof(long long));
				maxReps *= 2;
			}
		}
		else if (!(strcmp(line, "EVAL_MIN_ITER")))
			fscanf(fptr, "%d", &config.EVAL_MIN_ITER);
		else if (!(strcmp(line, "EVAL_ERROR")))
			fscanf(fptr, "%lf", &config.EVAL_ERROR);
		else if (!(strcmp(line, "PRE_EPSILON")))
			fscanf(fptr, "%lf", &config.PRE_EPSILON);
		else if (!(strcmp(line, "EPSILON")))
			fscanf(fptr, "%lf", &config.EPSILON);
		else if (!(strcmp(line, "BOOTSTRAP_REP")))
			fscanf(fptr, "%d", &config.BOOTSTRAP_REP);
		else if (!(strcmp(line, "MULTIPLE_REP")))
			fscanf(fptr, "%d", &config.MULTIPLE_REP);
		else if (!strcmp(line, "//"))
			fgets(comment, 2*BLOCKSIZE, fptr);
		else {
			printf ("%s\n", line);
			errMsg("read", "readConfig", "unrecognized parameter in configuration file", 1);
		}
	}

	fclose(fptr);

	if ( config.MULTIPLE_REP == 0 )
		config.NUM_REPS = 1;

	return 0;
}//END readConfig_jl()

/* Clone the problem from lp and populate into core structure.
 * Needed to ensure that：lp points to a valid lp problem,
 * possibly from another environment, ** but must have same cplex version. **
 */
oneProblem *populateCore(LPptr src, string probName) {
	oneProblem      *orig;
	int				c, nzcnt;

	check_env();
	int status;
	LPptr lp = CPXcloneprob(env, src, &status);
	if (status != 0)
		errMsg("Julia", "populateCore", "Failed to clone problem. Is lp pointer valid?", status);

	// To fix empty objective name, we manually override it to "OBJ"
	status = CPXcopyobjname(env, lp, "OBJ");
	if (status != 0)
		errMsg("Julia", "populateCore", "Failed to set objective name.", status);

	
	/* Allocate memory to the elements of problem and assign default values*/
	orig = (oneProblem *) mem_malloc(sizeof(oneProblem));
	orig->lp = lp;
	orig->name = (string) mem_calloc(NAMESIZE, sizeof(char));

	/* obtain type of problem read */
	orig->type = getProbType(lp);

	/* obtain the problem elements */
	/* (1) problem name */
	strcpy(orig->name, probName);

	/* (2) objective sense */
	orig->objsen = getObjSen(lp);
	if (!(orig->objsen))
		errMsg("solver", "readCore", "failed to obtain the objective sense", 1);

	/* (3) number of rows */
	orig->mar = getNumRows(lp);
	if (!(orig->mar))
		errMsg("solver", "readCore", "failed to obtain the number of rows in the problem", 1);

	/* (4) number of columns */
	orig->mac = getNumCols(lp);
	if (!(orig->mac))
		errMsg("solver", "readCore", "failed to obtain the number of columns in the problem", 1);

	/* (5) number of non-zeros */
	nzcnt = getNumnz(lp);

	/* continue allocating memory to the elements of problem and assign default values*/
	orig->objx = (vector) mem_calloc(orig->mac, sizeof(double));
	orig->rhsx = (vector) mem_calloc(orig->mar, sizeof(double));
	orig->senx = (string) mem_malloc(orig->mar*sizeof(char));
	orig->matbeg = (intvec) mem_malloc(orig->mac*sizeof(int));
	orig->matcnt = (intvec) mem_malloc(orig->mac*sizeof(int));
	orig->matind = (intvec) mem_malloc(nzcnt*sizeof(int));
	orig->matval = (vector) mem_malloc(nzcnt*sizeof(double));
	orig->bdl = (vector) mem_malloc(orig->mac*sizeof(double));
	orig->bdu = (vector) mem_malloc(orig->mac*sizeof(double));
	orig->ctype = (string) mem_malloc(orig->mac*sizeof(char));

	/* (6) objective function coefficients */
	if ( (getObjx(lp, 0, orig->mac, orig->objx)) )
		errMsg("solver", "readCore", "failed to obtain the objective coefficients", 1);

	/* (7) constraint right hand side */
	if ( (getRhsx(lp, 0, orig->mar, orig->rhsx)) )
		errMsg("solver", "readCore", "failed to obtain problem constraint right hand sides", 1);

	/* (8) constraint sense */
	if ( (getSense(lp, 0, orig->mar, orig->senx)))
		errMsg("solver", "readCore", "failed to obtain problem constraint sense", 1);

	/* (10) constraint matrix coefficients */
	if ( (getCols(lp, 0, orig->mac, orig->matbeg, orig->matind, orig->matval, nzcnt)) )
		errMsg("solver", "readCore", "failed to obtain the constraint matrix coefficients", 1);
	for ( c = 0; c < orig->mac - 1; c++ )
		orig->matcnt[c] = orig->matbeg[c+1] - orig->matbeg[c];
	orig->matcnt[c] = nzcnt - orig->matbeg[c];

	/* (11) problem variable bounds */
	if( getLb(lp, 0, orig->mac, orig->bdl) )
		errMsg("solver", "readCore", "failed to obtain the problem lower bounds", 1);
	if( getUb(lp, 0, orig->mac, orig->bdu) )
		errMsg("solver", "readCore", "failed to obtain the problem upper bounds", 1);

	if ( orig->type == PROB_MILP || orig->type == PROB_MIQP ) {
		/* (12) get problem constraint type */
		if ( getCtype(lp, 0, orig->mac, orig->ctype) )
			errMsg("solver", "readCore", "failed to obtain the variable types", 1);
		orig->numInt = getNumInt(lp);
		orig->numBin = getNumBinary(lp);
	}
	else {
		for ( c = 0; c < orig->mac; c++ )
			orig->ctype[c] = 'C';
		orig->numInt = 0;
	}

	/* Allocate memory to hold the names of problem elements */
	orig->objname = (string) mem_calloc(NAMESIZE, sizeof(char));
	orig->cstorsz = -getCstoreSize(lp, 0, orig->mac);
	if ( orig->cstorsz <= 0 )
		errMsg("solver", "readCore", "Could not determine amount of space for column names", 1);
	orig->cname = (string *) mem_malloc(orig->mac*sizeof(char *));
	orig->cstore = (string) mem_malloc(orig->cstorsz);

	orig->rstorsz = -getRstoreSize(lp, 0, orig->mar);
	if ( orig->rstorsz < 0 )
		errMsg("solver", "readCore", "Could not determine amount of space for row names", 1);
	orig->rname = (string *) mem_malloc(orig->mar*sizeof(char *));
	orig->rstore = (string) mem_malloc(orig->rstorsz);

	/* (12) objective name */
	if ( (getObjName(lp, orig->objname)) )
		errMsg("solver", "readCore", "failed to obtain objective name", 1);

	/* (13) problem row name */
	if ( (getRowName(lp, 0, orig->mar, orig->rname, orig->rstore, orig->rstorsz)) )
		errMsg( "solver", "readCore", "failed to obtain row names", 1);

	/* (14) problem column name */
	if ( (getColName(lp, 0, orig->mac, orig->cname, orig->cstore, orig->cstorsz)) )
		errMsg("solver", "readCore", "failed to obtain column names", 1);

	orig->matsz = nzcnt;
	orig->macsz = nzcnt;
	orig->marsz = nzcnt;
	orig->numnz = nzcnt;

	return orig;

}//END populateCore()

void dumpCore(oneProblem *orig)
{
	printf("=== dumpCore ===\n");
	printf("lp = %p\n", orig->lp);
	printf("type = %d\n", orig->type);
	printf("objsen = %d\n", orig->objsen);
	printf("rows\trname\tsenx\trhsx\tmar=%d\n", orig->mar);
	for(int i = 0; i < orig->mar; ++i)
		printf("%d\t%s\t%c\t%g\n", i, orig->rname[i], orig->senx[i], orig->rhsx[i]);
	
	printf("cols\tcname\tctype\tbdl\tbdu\tmac=%d\n", orig->mac);
	for(int i = 0; i < orig->mac; ++i)
		printf("%d\t%s\t%c\t%g\t%g\n", i, orig->cname[i], orig->ctype[i],
		orig->bdl[i], orig->bdu[i]);
}

void dumpStoc(stocType *stoc)
{
	printf("=== dumpStoc ===\n");
	printf("type = %s\n", stoc->type);
	printf("sim = %d\n", stoc->sim);
	printf("numOmega = %d\n", stoc->numOmega);
	printf("numGroups = %d\n", stoc->numGroups);
	printf("groupBeg = %d\n", stoc->groupBeg[0]);
	printf("row\tcol\tmean = ..\n");
	for (int i = 0; i < stoc -> numOmega; ++i)
		printf("%d\t%d\t%f\n", stoc->row[i], stoc->col[i], stoc->mean[i]);
	printf("\n");
}

void dumpTime(timeType *tim)
{
	printf("=== dumpTime ===\n");
	printf("nr = %d\n", tim->numRows);
	printf("nc = %d\n", tim->numCols);
	printf("stgNames = %s %s\n", tim->stgNames[0], tim->stgNames[1]);
	printf("row = %d %d\n", tim->row[0], tim->row[1]);
	printf("col = %d %d\n", tim->col[0], tim->col[1]);
}

/* Build an implicit two stage time structure by
 * specifying index of the stage split.
 * The index starts from zero! */
timeType *buildTwoStageTime(int split_row, int split_col) {
	timeType *tim = (timeType *) mem_malloc(sizeof(timeType));

	tim->type = 0;
	tim->probName = "JuliaExportProblem";
	tim->numStages = 2;

	tim->stgNames = (string *) mem_malloc(sizeof(string *) * 2);
	tim->stgNames[0] = "TIME1";
	tim->stgNames[1] = "TIME2";

	tim->row = (int *) mem_malloc(sizeof(int) * 2);
	tim->row[0] = 0;
	tim->row[1] = split_row;

	tim->col = (int *) mem_malloc(sizeof(int) * 2);
	tim->col[0] = 0;
	tim->col[1] = split_col;

	tim->numRows = 2;
	tim->rowStg = NULL;
	tim->numCols = 2;
	tim->colStg = NULL;

	return tim;
}

/* Build a special stoc struct with type EXT_GENERATOR.
 * When generateOmega() detects this keyword, 
 * it calls the handle void (* ext_generator)(vector observ)
 * The user is responsible for populating observ with one
 * realization of the random variables. */
stocType *buildExtStocType(int numOmega,
	intvec row, intvec col, vector mean,
	void (* ext_generator)(vector))
{
	stocType *stoc = (stocType *) mem_malloc(sizeof(stocType));
	stoc->type = "EXT_GENERATOR";
	stoc->sim = 1;
	stoc->numOmega = numOmega;
	stoc->numGroups = 1;

	stoc->row = (int *) mem_malloc(sizeof(int) * numOmega);
	for(int i = 0; i < numOmega; ++i)
		stoc->row[i] = row[i];

	stoc->col = (int *) mem_malloc(sizeof(int) * numOmega);
	for(int i = 0; i < numOmega; ++i)
		stoc->col[i] = col[i];

	/* We leave numVals, vals, probs NULL, so any
	 * attempt to access these will result in crash. */
	stoc->numVals = NULL;
	stoc->vals = NULL;
	stoc->probs = NULL;

	/* In this fake stoc type, we treat everything
	 * as a single group. */
	stoc->numPerGroup = (int *) mem_malloc(sizeof(int));
	stoc->numPerGroup[0] = numOmega;
	stoc->groupBeg = (int *) mem_malloc(sizeof(int));
	stoc->groupBeg[0] = 0;

	stoc->mean = (double *) mem_malloc(sizeof(double) * numOmega);
	memcpy(stoc->mean, mean, sizeof(double) * numOmega);

	stoc->mod = NULL;
	stoc->ext_generator = ext_generator;
	
	return stoc;
}

