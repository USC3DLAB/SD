using JuMP, CPLEX

N = 72000
r = -rand(N)
s = r .+ 1.0

model = direct_model(optimizer_with_attributes(
    CPLEX.Optimizer, CPLEX.PassNames() => true
))
# Diamond Example
# IMPORTANT! Only use callbacks in single-threaded mode!
# Have the user input the variables/constraints in stage order!
@variable(model, 0.0 <= x <= 5.0)
@variable(model, y[1:N, 1:4] >= 0.0)
@constraint(model, sec_con1[i = 1:N], -y[i, 1] +y[i, 2] -y[i, 3] +y[i, 4] ==  0.5*x+r[i])
@constraint(model, sec_con2[i = 1:N], -y[i, 1] +y[i, 2] +y[i, 3] -y[i, 4] ==  0.25*x+s[i])

@objective(model, Min, -0.75*x + 1/N*sum((-y[i, 1] + 3*y[i, 2] +y[i, 3] + y[i, 4]) for i in 1:N)) 
optimize!(model)
@show objective_value(model)
@show value(x)

# # Mean prob
# model = Model(CPLEX.Optimizer)
# @variable(model, 0 <= x <= 5)
# @variable(model, y[1:4] >= 0)
# @constraint(model, sec_con1, -y[1] +y[2] -y[3] +y[4] ==  0.5*x-0.5)
# @constraint(model, sec_con2, -y[1] +y[2] +y[3] -y[4] ==  0.25*x+0.5)

# stage_objectives = [(-0.75*x), (-y[1] + 3*y[2] + y[3] + y[4])]
# @objective(model, Min, sum(stage_objectives))
# optimize!(model)
# objective_value(model)