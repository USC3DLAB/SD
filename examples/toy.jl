using JuMP, CPLEX

# Trivial Example
# COR section
model = direct_model(optimizer_with_attributes(
    CPLEX.Optimizer, CPLEX.PassNames() => true
))

@variable(model, y)
@constraint(model, s, y >= -1)

@objective(model, Min, y)

# TIM section
split_position = Position(s, y)

# STOC section
function mystoc()::OneRealization
    return OneRealization([
        Position(s, "RHS") => rand() - 1
    ])
end

user_mean = [1.0]
