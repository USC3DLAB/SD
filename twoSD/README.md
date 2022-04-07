# Stochastic Decomposition 

Stochastic decomposition (SD) is a sequential sampling-based algorithm for two-stage stochastic linear programs (2-SLP). The algorithmic details can be found in:

1. Higle, J. L. and Sen, S. (1994). Finite master programs in regularized stochastic decomposition. Mathematical Programming, 67(1):143–168.
2. Sen, S. and Liu, Y. (2016). Mitigating uncertainty via compromise decisions in two-stage stochastic linear programming: Variance reduction. Operations Research, 64(6):1422–1437.
3. Gangammanavar, H., Liu, Y. and Sen, S. (2018) Stochastic Decomposition for Two-stage Stochastic Linear Programs with Random Cost Coefficients, available on Optimization Online.

This software is developed by Jason Mai, Lei Zhao, Yifan Liu, and Harsha Gangammanavar and Suvrajeet Sen.

### Support
Please report bugs [here on GitHub](https://github.com/USC3DLAB/SD/issues).

## Version information: 
`v1.0`: Supports 2-SLPs with randomness in right-hand side and the technology matrix.  
`v2.0`: Supports 2-SLPs with randomness in right-hand side vector, the technology matrix and cost coefficient vector.

## Input file format
The implementation of accepts stochastic programs described using the SMPS file format:

* Core file: Describes the optimization problem corresponding to a single scenario
* Time file: Provides information regarding decomposition of the problem into master and subproblem
* Stoch file: Describes the stochastic information associated with the problem. (Currently, INDEP and BLOCK types are supported)

For more information about the SMPS file format [here](https://doi.org/10.1137/1.9780898718799.ch2)

## Installation
Note: Only Unix systems have been tested.
#### Prerequisite: 
  * CPLEX should be available on your machine. Trial version is available [here](http://www-01.ibm.com/software/commerce/optimization/cplex-optimizer/).
  * Git, if you want to directly use the commands below.

#### Steps
  1. Download the SD source codes.  
    * `git clone https://github.com/USC3DLAB/SD`  
  2. For `v1.0`  
    * Checkout the version with: `git checkout v1.0`  
    * Follow instructions in the README file.  
  3. For `v2.0`  
    * Change into source directory: `cd SD`  
    * Check the `makefile` to make sure that the cplex installation directory is correct for your system.  
    * Compile the code: `make all`  
  4. Setup a directory to write output files.  
    * `mkdir spOutput`  
  5. Execute the algorithm by invoking the executable with three inputs (i) problem name, (ii) directory where the problem files reside, and (iii) directory where you wish output files be written.  
    * `./twoSD problem_name input_directory_path output_directory_path`  
    * Example: `./twoSD pgp2 ./spInput ./spOutput`  

A collection of classical 2-SLP problems are included in the `spInput` folder. Results will be stored in `spOutput/problem_name` folder. Please check `pgp2.detailed_soln.out` for solutions and `time_sample.out` for CPU time and number of samples used.
