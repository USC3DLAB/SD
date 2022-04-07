module SDTypes

# type definitions in utils.h
Cvector = Ptr{Cdouble}
Cintvec = Ptr{Cint}
CBOOL = Cuint

struct sparseVector
    cnt::Cint
    col::Cintvec
    val::Cvector
end

struct sparseMatrix
    cnt::Cint
    col::Cintvec
    row::Cintvec
    val::Cvector
end

# type definitions in smps.h
struct oneProblem
    type::Cint	# type of problem: LP, QP, MIP or MIQP 
    lp::Ptr{Cvoid}	# problem pointer to be used by solver 
    name::Cstring	# name of the problem 
    objsen::Cint	# sense of the objective: 1 for minimization and -1 for maximization 
    mac::Cint	# number of columns 
    mar::Cint	# number of rows 
    numBin::Cint	# number of binary variables in the problem 
    numInt::Cint	# number of integer variables in the problem 
    numnz::Cint	# number of non-zero elements in constraint matrix 
    objx::Cvector	# objective function coefficients 
    rhsx::Cvector	# right-hand side 
    senx::Cstring	# constraint sense 
    matbeg::Cintvec	# sparse matrix representation: column beginning 
    matcnt::Cintvec	# sparse matrix representation: number of non-zero entries in a column 
    matind::Cintvec	# sparse matrix representation: rows with non-zero entries 
    matval::Cvector	# sparse matrix representation: non-zero coefficients of the matrix 
    bdl::Cvector	# lower bound 
    bdu::Cvector	# upper bound 
    ctype::Cstring	# type of decision variables: 'C' continuous, 'B' binary, 'I' general integer, 'S' semi-continuous, 'N' semi-integer 
    objname::Cstring	# objective function name 
    rstorsz::Cint	# memory size for storing row names 
    rname::Ptr{Cstring}	# vector of row names 
    rstore::Cstring	# row names string 
    cstorsz::Cint	# memory size for storing column names 
    cname::Ptr{Cstring}	# vector of column names 
    cstore::Cstring	# column name string 
    macsz::Cint	# extended column size 
    marsz::Cint	# extended row size 
    matsz::Cint	# extended matrix size 
end

struct timeType
    type::Cint	# type of time file declaration, 0 for implicit and 1 for explicit 
    probName::Cstring	# name of the problem as read from time file 
    numStages::Cint	# number of stages in the problem 
    stgNames::Ptr{Cstring}	# unique strings to identify stages
    row::Cintvec	# a list of row names which mark the beginning of a new stage 
    col::Cintvec	# a list of column names which mark the beginning of a new stage 
    numRows::Cint	# used with explicit time file declaration only, set to numStages in implicit declaration 
    rowStg::Cintvec	# used with explicit time file declaration only 
    numCols::Cint	# used with explicit time file declaration only, set to numStages in implicit declaration 
    colStg::Cintvec	# used with explicit time file declaration only 
end

struct stocType
    type::Cstring	# type of stocType being used 
    sim::CBOOL	# set to TRUE if an external simulator is used 
    numOmega::Cint	# number of stochastic elements stored in structure 
    numGroups::Cint;
    row::Cintvec	# row number array in the original problem; -1 indicates objective function 
    col::Cintvec	# column number array in the original problem; -1 indicates right-hand side 
    numVals::Cintvec	# number of realization for each random variable 
    vals::Ptr{Cvector}	# indexed array of discrete realizations of random variable 
    probs::Ptr{Cvector}	# indexed array of probabilities associated with discrete realizations
    numPerGroup::Ptr{Cintvec};
    groupBeg::Ptr{Cintvec};
    mean::Cvector	# mean of each rv 
    mod::Ptr{Cvoid} # ??? statModel *mod;
    ext_generator::Ptr{Cvoid} # external generator
end

struct oneCut
    alpha::Cdouble # scalar value for the righ-hand side
    beta::Cvector # coefficients of the master problems's primal variables
    numSamples::Cint # number of samples on which the given cut was based
    omegaCnt::Cint # number of *distinct* observations on which the cut is based (this is also the length of istar)
    iStar::Cintvec # indices of maximal pi for each distint observation
    isIncumb::CBOOL # indicates if the cut is an incumbent cut
    alphaIncumb::Cdouble # right-hand side when using QP master, this is useful for quick updates
    slackCnt::Cint # number of times a cut has been slack, used in deciding when the cut needs to be dropped
    rowNum::Cint # row number for master problem in solver
    name::Cstring # ???
end

struct cutsType
    cnt::Cint # number of cuts
    vals::Ptr{Ptr{oneCut}}
end

export oneProblem, timeType, stocType, sparseVector, sparseMatrix

end
