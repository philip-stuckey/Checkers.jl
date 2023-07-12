module BruteForce

using Combinatorics
using CUDA
include("core.jl")
using .CheckersCore: covered
using ProgressMeter
import Dates

export brute_force, num_solutions

"""
brute_force(n, M=ceil(Int, n * n / 5):(n*n))

Runs the brute force algorithm to solve the checkers problem.

Args:
- `n`: The size of the checkers board (n x n).
- `M`: The range of task sizes to consider (default: 1/5 to n^2).

Returns:
- A tuple `(solution, m)` where `solution` is a boolean array representing the solved checkers board
  and `m` is the task size that resulted in the solution.
"""
function brute_force(n, M=ceil(Int, n * n / 5):(n*n))
    h_solution = Vector{Tuple{Array{Bool, 2}, Int}}(undef, 1)  # host array to store solution
    total_combinations = length(collect(Combinatorics.Combinations(n * n, maximum(M))))
    p = Progress(total_combinations, 1, "Progress: ", " Combinations: ")

    for (i, m) in enumerate(M)
        combinations = collect(Combinatorics.Combinations(n * n, m))  # Convert Combinations object to array
        num_tried = 0
        start_time = now()
        for combination in combinations
            CUDA.@sync begin
                d_board = CUDA.zeros(Bool, n, n)  # allocate a GPU array
                d_board[combination] .= 1  # put a 1 on every part of the board specified by that combination of indices
            end
            num_tried += 1
            if CUDA.@sync covered(d_board)
                h_solution[1] = (CUDA.to_host(copy(d_board)), m)  # if we find any solution, store it in the host array
                elapsed_time = Dates.now() - start_time
                iterations_per_second = num_tried / Dates.value(Dates.Millisecond(elapsed_time))
                println("Solution found!")
                println("Combination: ", combination)
                println("Combinations tried: ", num_tried, "/", total_combinations)
                println("Iterations per second: ", iterations_per_second)
                return h_solution[1]  # exit the function early
            end
            next!(p)  # update the progress bar
        end
        done!(p)  # mark the progress bar as done
    end

    # If no solution is found, return an empty boolean array
    return (Bool[;;], 0)
end

"""
num_solutions(n, M=ceil(Int, n * n / 5):(n*n))

Counts the number of solutions for the checkers problem.

Args:
- `n`: The size of the checkers board (n x n).
- `M`: The range of task sizes to consider (default: 1/5 to n^2).

Returns:
- The number of solutions found.
"""
function num_solutions(n, M=ceil(Int, n * n / 5):(n*n))
    num_solutions = 0
    total_combinations = length(collect(Combinatorics.Combinations(n * n, maximum(M))))
    p = Progress(total_combinations, 1, "Progress: ", " Combinations: ")

    for (i, m) in enumerate(M)
        combinations = collect(Combinatorics.Combinations(n * n, m))  # Convert Combinations object to array
        for combination in combinations
            CUDA.@sync begin
                d_board = CUDA.zeros(Bool, n, n)  # allocate a GPU array
                d_board[combination] .= 1  # put a 1 on every part of the board specified by that combination of indices
            end
            if CUDA.@sync covered(d_board)
                num_solutions += 1
            end
            next!(p)  # update the progress bar
        end
        done!(p)  # mark the progress bar as done
    end

    return num_solutions
end

end
