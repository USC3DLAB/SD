directory src
set breakpoint pending on
target exec julia
b algo.c:18
r julia/SDJulia.jl