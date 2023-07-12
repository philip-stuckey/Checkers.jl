using CUDA
using ProgressBars
import Combinatorics
include("brute_force.jl")
import .BruteForce

# Run the brute force algorithm for a range of task sizes
function run_brute_force(n)
	if n < 1
		throw(MethodError("Invalid board size: $n. Board size must be at least 1."))
	end
    M = 1:10:n
    h_solution = Vector{Tuple{Array{Bool, 2}, Int}}(undef, 1)  # host array to store solution

    total_tasks = length(M)
    for (i, m) in enumerate(M)
        combinations = Combinatorics.combinations(1:(n*n),m)
        println("Progress: $i / $total_tasks")
        for combination in combinations
            CUDA.@sync begin
                d_board = CUDA.zeros(Bool, n, n)  # allocate a GPU array
                d_board[combination] .= 1  # put a 1 on every part of the board specified by that combination of indices
            end
            if CUDA.@sync BruteForce.covered(d_board)
                h_solution[1] = (CUDA.to_host(copy(d_board)), m)  # if we find any solution, store it in the host array
                return h_solution[1]  # exit the function early
            end
        end
    end

    return (Bool[;;], 0)  # if the function gets this far, presumably no solutions exist
end

# Main entry point
function main()
    n = 3
    CUDA.allowscalar(false)
    @info "Running brute force algorithm for n = $n"
    solution = run_brute_force(n)
    println("Solution found: ", solution)
end

main()
