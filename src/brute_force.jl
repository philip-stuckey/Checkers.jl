module BruteForce
using Combinatorics
using CUDA
using ...CheckersCore: covered

export brute_force, num_solutions

"""
    brute_force(n, M=ceil(Int, n * n / 5):(n*n))

    Finds the minimum number of "1"s required to cover a square matrix of side
    length n. It does this by first looking for any covered boards with 1 "1" on 
    them, then any board with 2 "1"s, etc... If at any point it finds one, it 
    returns immediately because it always exhausts boards with fewer "1"s first,
    therefore the first covered board it finds must be a minimal one.
"""
function brute_force(n, M=ceil(Int, n * n / 5):(n*n))
    d_board = CUDA.zeros(Bool, n, n)  # allocate a GPU array
    h_solution = Vector{Tuple{Array{Bool, 2}, Int}}(undef, 1)  # host array to store solution

    for m in M
        combinations = Combinatorics.Combinations(n * n, m)
        for combination in combinations
            CUDA.@sync begin
                d_board .= 0  # Start by clearing the old board
                d_board[combination] .= 1  # put a 1 on every part of the board specified by that combination of indices
            end
            if CUDA.@sync covered(d_board)
                h_solution[1] = (CUDA.to_host(copy(d_board)), m)  # if we find any solution, store it in the host array
                return h_solution[1]  # exit the function early
            end
        end
    end
    return (Bool[;;], 0)  # if the function gets this far, presumably no solutions exist
end

function num_solutions(n, m)
    d_board = CUDA.zeros(Bool, n, n)  # allocate a GPU array
    result = CUDA.zeros(Int)
    combinations = Combinatorics.Combinations(n * n, m)

    for combination in combinations
        CUDA.@sync begin
            d_board .= 0  # Start by clearing the old board
            d_board[combination] .= 1  # put a 1 on every part of the board specified by that combination of indices
        end
        if CUDA.@sync covered(d_board)
            @cuda atomic add!(result, 1)
        end
    end

    return CUDA.to_host(result[1])
end

end
