using JuMP, CPLEX

"""
Read MPS file format inputFilePath, and output corresponding
LP file format to outputFilePath.
"""
function mps_to_lp(inputFilePath::String, outputFilePath::String)
    model = direct_model(CPLEX.Optimizer())
    cpx_model = backend(model)
    CPXreadcopyprob(cpx_model.env, cpx_model.lp, inputFilePath, "MPS")
    CPXwriteprob(cpx_model.env, cpx_model.lp, outputFilePath, "LP")
end

