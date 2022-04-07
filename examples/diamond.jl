# Diamond Example as descibed in SD Book Page 89
using JuMP, CPLEX

# Diamond Example
# COR section
model = direct_model(optimizer_with_attributes(
    CPLEX.Optimizer, CPLEX.PassNames() => true
))

@variable(model, 0.0 <= x <= 5.0)

@variable(model, y[1:4] >= 0.0)
@constraint(model, sec_con1, -y[1] +y[2] -y[3] +y[4] ==  1+ 0.5*x)
@constraint(model, sec_con2, -y[1] +y[2] +y[3] -y[4] ==  0.25*x)

stage_objectives = [(-0.75*x), (-y[1] + 3*y[2] + y[3] + y[4])]
@objective(model, Min, sum(stage_objectives))

# TIM section
split_position = Position(sec_con1, y[1])

# STO section
user_mean = [-0.5, 0.5]

function mystoc()::OneRealization
    r = -rand()
    s = 1+r

    return OneRealization([
        Position(sec_con1, "RHS") => r,
        Position(sec_con2, "RHS") => s
    ])
end
