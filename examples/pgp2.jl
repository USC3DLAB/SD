# PGP2 Example
# SD Book Page 6
# https://core.isrd.isi.edu/chaise/record/#1/Core:Instance/RID=W17E

using TwoSD
using CPLEX, JuMP
using Distributions

# DATA
# Dimensions
m = 3  # I
n = 4  # J

# Annualized capital cost $/kw
c = [10.0, 7.0, 16.0, 6.0]

# f: Cost of producing a unit of energy $/kwh
f = [40.0, 45.0, 32.0, 55.0]

# beta: load duration h
beta = [1, 0.6, 0.1]

# Budget $
b = 220

# Minimum capacity
M = 15

# Penalty for subcontracting (see Page 31)
p = 1000

# Distribution of random variable
d_value = [
    [0.5, 1.0, 2.5, 3.5, 5.0, 6.5, 7.5, 9.0, 9.5],
    [0.0, 1.5, 2.5, 4.0, 5.5, 6.5, 8.0, 8.5],
    [0.0, 0.5, 1.5, 3.0, 4.5, 5.5, 7.0, 7.5]
]

d_prob = [
    [5.0e-5, 0.00125, 0.0215, 0.2857, 0.383, 0.2857, 0.0215, 0.00125, 5.0e-5],
    [0.0013, 0.0215, 0.2857, 0.383, 0.2857, 0.0215, 0.00125, 5.0e-5],
    [0.0013, 0.0215, 0.2857, 0.383, 0.2857, 0.0215, 0.00125, 5.0e-5]
]

d_distribution = product_distribution(
    collect(DiscreteNonParametric(d_value[i], d_prob[i]) for i in 1:3)
)

# Mean of the random variables
d_bar = mean(d_distribution)

# COR
model = direct_model(optimizer_with_attributes(
    CPLEX.Optimizer, CPLEX.PassNames() => true
))

# stage 1
@variable(model, x[1:n] >= 0)
@constraint(model, BUDGET, c'x <= b)
@constraint(model, MXDEMD, sum(x) >= M)

# stage 2
@variable(model, y[1:m, 1:n] >= 0)
@variable(model, pen[1:n] >= 0) # Penalty terms

@constraint(model, CAP, -x -pen + dropdims(sum(y; dims=1); dims=1) .<= 0)
@constraint(model, DNODE, dropdims(sum(y; dims=2); dims=2) .>= d_bar)

stage_objectives = [(c'x), sum(beta * f' .* y) + sum(p*pen)]
@objective(model, Min, sum(stage_objectives))

# TIM
split_position = Position(CAP[1], y[1,1])

# STOC
using Random
rng = MersenneTwister(1234)
function mystoc()::OneRealization
    pos = [Position(DNODE[i], "RHS") for i in 1:3]
    val = rand(rng, d_distribution)

    return OneRealization([pos[i] => val[i] for i in 1:3])
end

user_mean = d_bar

solve_sd(model, split_position, user_mean, mystoc)