using StochasticDecomposition.SDTypes: oneCut, cutsType

function read_cuts(ptr::Ptr{cutsType}, x_dim::Integer)
    pool = unsafe_load(ptr)
    if pool.cnt == 0
        return Nothing
    end

    # a + Bx
    B = zeros(pool.cnt, x_dim)
    a = zeros(x_dim)

    cutpool = unsafe_wrap(Array{Ptr{oneCut}}, pool.vals, pool.cnt)
    for (i, cut_p) in enumerate(cutpool)
        cut::oneCut = unsafe_load(cut_p)
        alpha = cut.alpha
        # beta: need to know how many X are there
        beta = unsafe_wrap(Array{Cdouble}, cut.beta, x_dim)

        a[i] = alpha
        B[i, :] = beta
    end

end

p = Ptr{cutsType}(0x000000006ec0f5d0)
read_cuts(p, 8)

