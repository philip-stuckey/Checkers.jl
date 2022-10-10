module StochasticSearch

using Random
using Combinatorics
using ...CheckersCore: neighbors, covered, Pad

export stochastic_search, brute_force2

is_hole(A) = [is_hole(A, I) for I in CartesianIndices(A)]
is_hole(A, I) = !covered(A, I)

holes(m::AbstractMatrix{T}; fill=zero(T)) where {T} = holes(Pad(m, fill))
holes(p::Pad) = sum(neighbors(p) .== 0)

covering(A, I) = A[I] * count(==(0), neighbors(A, I, fill=one(eltype(A))))

function update!(A)
    (_, holeIndex) = findmax(neighbors(is_hole(A)))
    (_, tokenIndex) = find_min_covering(A)
    @assert A[holeIndex] == 0
    @assert A[tokenIndex] == 1
    A[holeIndex] = 1
    A[tokenIndex] = 0
    return A
end

"""
    find_min_covering(A)

 
find the checker which covers the fewest other tiles	
"""
function find_min_covering(A)
    I = filter(I -> A[I], CartesianIndices(A)) |> collect
    (c, II) = findmin(I -> covering(A, I), I)
    return (c, I[II])
end


function stochastic_search(
    n::Int,
    m::Int;
    init=reshape(shuffle(vcat(ones(Bool, m), zeros(Bool, n * n - m))), n, n),
    attempts=10^7,
    (update!)=update!
)
    A = copy(init)
    for n in 1:attempts
        prev_holes = holes(A)
        update!(A)
        next_holes = holes(A)
        while next_holes > 0 && prev_holes > next_holes
            prev_holes = next_holes
            update!(A)
            next_holes = holes(A)
        end
        holes(A) == 0 && return A
        shuffle!(A)
    end
    return Bool[;;]
end


function brute_force2(n, M=ceil(Int, n * n / 5):(n*n))
    board = zeros(Bool, n, n)  # pre-allocate a board
    for m in M
        # make an iterator over every combination of indices length m. These is where we'll put the 1s
        combos = combinations(vcat(ones(Bool, m), zeros(Bool, (n^2) - m)), n * n)
        #@info "$(now())" m  log10(length(combinations))
        for combination in combos  # most of the allocations happen here
            A = reshape(combination, n, n)
            prev_holes = holes(A)
            update!(A)
            next_holes = holes(A)
            while next_holes > 0 && prev_holes > next_holes
                prev_holes = next_holes
                update!(A)
                next_holes = holes(A)
            end
            holes(A) == 0 && return A
        end
    end
    return (Bool[], 0)  # if the function gets this far, presumably no solutions exist
end

end