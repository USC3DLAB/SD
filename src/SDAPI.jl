module SDAPI

using ..SDTypes
using Libdl

# store pointer address to functions in SD libraries
const openSolver_p = Ref{Ptr{Cvoid}}(0)
const env_pp = Ref{Ptr{Cvoid}}(0)
const readConfig_jl_p = Ref{Ptr{Cvoid}}(0)
const populateCore_p = Ref{Ptr{Cvoid}}(0)
const buildTwoStageTime_p = Ref{Ptr{Cvoid}}(0)
const buildExtStocType_p = Ref{Ptr{Cvoid}}(0)
const dumpCore_p = Ref{Ptr{Cvoid}}(0)
const dumpTime_p = Ref{Ptr{Cvoid}}(0)
const dumpStoc_p = Ref{Ptr{Cvoid}}(0)
const algo_p = Ref{Ptr{Cvoid}}(0)

const config_path = Ref{String}()
const output_path = Ref{String}()



# Load the SD library and find all the functions
function __init__()
    # System dependent library format name
    if Sys.iswindows()
        ext = "dll"
    else
        ext = "so"
    end
    # Add current folder and parent to library search path
    sd_dir_path = joinpath(dirname(@__DIR__()), "twoSD")
    twosd_path = joinpath(sd_dir_path, "libtwosd." * ext)
    # Load the library
    twosd = dlopen(twosd_path)

    # Get pointers
    openSolver_p[] = dlsym(twosd, :openSolver)
    env_pp[] = dlsym(twosd, :env)
    readConfig_jl_p[] = dlsym(twosd, :readConfig_jl)
    populateCore_p[] = dlsym(twosd, :populateCore)
    buildTwoStageTime_p[] = dlsym(twosd, :buildTwoStageTime)
    buildExtStocType_p[] = dlsym(twosd, :buildExtStocType)
    dumpCore_p[] = dlsym(twosd, :dumpCore)
    dumpTime_p[] = dlsym(twosd, :dumpTime)
    dumpStoc_p[] = dlsym(twosd, :dumpStoc)
    algo_p[] = dlsym(twosd, :algo)

    # Set up config_path and output_path
    config_path[] = joinpath(sd_dir_path, "config.sd")
    output_path[] = joinpath("./spOutput")

    nothing
end

# =================
# SD API's
openSolver() = ccall(openSolver_p[], Cvoid, ())

# CPXENV
get_env() = unsafe_load(cglobal(env_pp[], Ptr{Cvoid}))

readConfig_jl() = ccall(readConfig_jl_p[], Cint, (Cstring, Cstring), config_path[], output_path[])

populateCore(src::Ptr{Cvoid}, probName::String) = ccall(
    populateCore_p[], Ptr{oneProblem}, (Ptr{Cvoid}, Cstring), src, probName)

# These indices should start with 1. Pass directly the VariableIndex works.
# This function will automatically translate it.
buildTwoStageTime(split_row::Integer, split_col::Integer) =
    ccall(buildTwoStageTime_p[], Ptr{timeType}, (Cint, Cint), split_row-1, split_col-1)

buildExtStocType(numOmega::Integer,
    row::AbstractVector{<:Integer}, col::AbstractVector{<:Integer},
    mean::AbstractVector{<:AbstractFloat}, func::Union{Base.CFunction, Ptr{Cvoid}}) = ccall(buildExtStocType_p[],
    Ptr{stocType}, (Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cvoid}),
    numOmega,
    convert(Vector{Cint}, row.-1) , convert(Vector{Cint}, col.-1),
    convert(Vector{Cdouble}, mean), func)

# For inspection in C: user is responsible
# that the pointer is valid. If the object
# comes from julia using pointer_from_objref
# make sure it is not garbage collected!
dumpCore(orig) = ccall(dumpCore_p[], Cvoid, (Ptr{Cvoid}, ), orig)
dumpTime(tim) = ccall(dumpTime_p[], Cvoid, (Ptr{Cvoid}, ), tim)
dumpStoc(stoc) = ccall(dumpStoc_p[], Cvoid, (Ptr{Cvoid}, ), stoc)

# Main entrance
algo(orig::Ptr{oneProblem}, tim::Ptr{timeType}, stoc::Ptr{stocType}, inputDir::String, probName::String) = 
    ccall(algo_p[], Cint, (Ptr{oneProblem}, Ptr{timeType}, Ptr{stocType}, Cstring, Cstring),
    orig, tim, stoc, inputDir, probName)

end