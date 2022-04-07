# CEP
# Reference: SD Book Page 3
# https://core.isrd.isi.edu/chaise/record/#1/Core:Instance/RID=W182
using TwoSD
using CPLEX, JuMP

# Data section
c = [2.5, 3.75, 5.0, 3.0]
h = [500, 500, 500, 500]
t = [0.08, 0.04, 0.03, 0.01]
T = 100
u = [2000, 2000, 3000, 3000]

g = [
    2.6 3.4 3.4 2.5
    1.5 2.4 2.0 3.6
    4.0 3.8 3.5 3.2
]
p = [400, 400, 400]
a = [
    0.6 0.6 0.9 0.8
    0.1 0.9 0.6 0.8
    0.05 0.2 0.5 0.8
]

J = 4
I = 3

# COR
model = direct_model(optimizer_with_attributes(
    CPLEX.Optimizer, CPLEX.PassNames() => true
))
@variables(model, begin    
    x[1:J] >= 0
    z[1:J] >= 0
end)

set_upper_bound.(z, u)

@constraints(model, begin
HRS, -x+z .<= h
MAI, t' * z .<= T
end)

@variables(model, begin    
    y[1:I, 1:J] >= 0
    s[1:I] >= 0
end)

@constraints(model, begin
CAP, z - dropdims(sum(y; dims=1); dims=1) .>= 0
DEM, dropdims(sum(a.*y; dims=2); dims=2) + s .>= 1500
end)

stage_objectives = [(c'x), (sum(g.*y) + p's)]

@objective(model, Min, sum(stage_objectives))

# TIM
split_position = Position(CAP[1], y[1, 1])

# STO
using Random
rng = MersenneTwister(1234)
sampler = Random.Sampler(rng, collect(0.0:600:3000))
function mystoc()::OneRealization
    return OneRealization([Position(d, "RHS") => rand(rng, sampler) for d in DEM])
end

user_mean = [1500.0, 1500.0, 1500.0]
solve_sd(model, split_position, user_mean, mystoc)
