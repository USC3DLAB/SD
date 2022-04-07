module SDPosition
using JuMP

"""
Represents position of an r.v. realization, in Julia 1-based index.
Special cases: row = 0 means the objective. col = 0 means the RHS. 
"""
struct Position
    row::Union{ConstraintRef, String}
    col::Union{VariableRef, String}
end

struct IndexPosition
    row::Int
    col::Int
end

function pos_to_index(pos::Position, row_map, col_map)
    row::Int = pos.row == "OBJ" ? 0 : row_map[pos.row]
    col::Int = pos.col == "RHS" ? 0 : col_map[pos.col]
    return IndexPosition(row, col)
end

"""
Represents one realization of omega. This should
then be transformed into the internal representation
of row and column indices.
"""
struct OneRealization
    value::Vector{Pair{Position, <:AbstractFloat}}
end

# function OneRealization(vv::Vector{Tuple{Position, T}}) where T <: AbstractFloat
#     pairs = [u => v for (u, v) in vv]
#     return OneRealization(pairs)
# end

function get_pattern(r::OneRealization)::Vector{Position}
    v::Vector{Position} = [first(rr) for rr in r.value]
    return v
end
bind_pattern(v::Vector) = Dict(zip(v, range(1, length(v))))

export Position, RandomPattern, OneRealization
end