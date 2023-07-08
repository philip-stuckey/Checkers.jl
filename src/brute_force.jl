module BruteForce

using Combinatorics
using CUDA
using ...CheckersCore: covered
using ProgressMeter

export brute_force, num_solutions

function brute_force(n, M=ceil(Int, n * n / 5):(n*n))
    h_solution = Vector{Tuple{Array{Bool, 2}, Int}}(undef, 1)  # host array to store solution

    for (i, m) in enumerate(M)
        combinations = Combinatorics.Combinations(n * n, m)
        p = Progress(n, 1, "Progress: ", " Solved: $i/$n ", show_percentage = true)
        for combination in combinations
            CUDA.@sync begin
                d_board = CUDA.zeros(Bool, n, n)  # allocate a GPU array
                d_board[combination] .= 1  # put a 1 on every part of the board specified by that combination of indices
            end
            if CUDA.@sync covered(d_board)
                h_solution[1] = (CUDA.to_host(copy(d_board)), m)  # if we find any solution, store it in the host array
                return h_solution[1]  # exit the function early
            end
            next!(p)  # update the progress bar
        end
        done!(p)  # mark the progress bar as done
    end

    return (Bool[;;], 0)  # if the function gets this far, presumably no solutions exist
end

end
