# TwoSD

This is a Julia interface to SD solver, a program for solving two-stage stochastic program.

## Building

1. Compile SD

    You will need the following to compile SD, which is written in C.

    - CPLEX

        CPLEX is a proprietary MIP/LP solver. You can get an academic version or a trial version.

    - make
    - gcc

2. Specify in the Makefile where your CPLEX installation is.

    ```makefile
    CPLEXDIR = /opt/ibm/ILOG/CPLEX_Studio201/cplex
    ```

    Change this line as appropriate.

    (The following is for Windows build only.)

    ```makefile
    LIBS := -lcplex2010
    ```

    Change the library name as necessary, if you are using a different CPLEX version than 20.10.

3. Run "make all" under "twoSD" __subfolder__.

## Julia

This package can be installed under Julia's package manager. It can handle the dependency issue for you.

To avoid CPLEX issues, make sure you have set up CPLEX.jl and JuMP correctly in Julia before you install this package.

To install this package in development mode, change directory to where you placed the repository. Then open julia; go to Julia's package manager (by pressing "]" key in REPL), and type

```julia
dev "."
```

This will add Julia as a development package. Alternatively, under the package manager, you can type

```julia
activate .
```

to temporarily use TwoSD without installing it, but the dependency needs to be handled manually.

## Example

Several examples can be found in the example subfolder.
