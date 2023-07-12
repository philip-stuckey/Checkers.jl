# Checkers.jl

This Julia project aims to find the size of the minimum dominating set of an n by n grid graph.

## Table of Contents
- [Introduction](#introduction)
- [Definitions](#definitions)
- [Brute Force Search](#brute-force-search)
- [Stochastic Search](#stochastic-search)
- [Using CUDA](#using-cuda)
- [Building and Running the Project](#building-and-running-the-project)

## Introduction
The goal of this project is to determine the minimum number of checkers required to cover an n by n checkerboard, where a square is considered "covered" if it has a checker on it or is adjacent to a square with a checker (excluding diagonals). This problem is equivalent to finding the size of the minimum dominating set of an n by n grid graph.

Note that m ≧ n²/5, because each individual checker can cover, at most, 5 squares. 
Also, m < n²/2, because a board that has a checker on every other square is covered (very inefficiently).

## Definitions
Before discussing the solution methods, let's define some useful functions used in this project:

- `neighbors(z, (i, j))`: Returns the Von Neumann neighborhood (of radius 1) around the i,jth element of matrix x. `z` is a special matrix type that returns a default fill value if any of the indices are out of bounds.

- `covered(A, (i, j))`: Checks if a square is covered, i.e., it has a checker on it or is adjacent to a square with a checker on it.

- `covered(A)`: Checks if all squares on the board are covered.

- `is_hole(A, I)`: Determines if a square is a "hole," i.e., it is not covered.

- `is_hole(A)`: Returns a boolean matrix indicating which squares are holes.

- `holes(p)`: Computes the number of holes on a board.

- `covering(A, I)`: Computes the number of squares a square is covering.

## Brute Force Search
The brute force search method is a simple approach that guarantees a minimal solution but becomes computationally expensive as the board size increases due to the exponential increase in the search space.

The `brute_force` function starts with the smallest possible number of checkers `m` and increments it only when all boards have been exhausted. This optimization allows the function to find the first covered board it encounters, which must be a minimal covering board. The function returns this solution immediately, avoiding the need to search through the entire space.

```julia
using Combinatorics

function brute_force(n, M=ceil(Int, n * n / 5):(n*n))
    board = zeros(Bool, n, n)  # Pre-allocate a board
    for m in M
        combinations = Combinatorics.Combinations(n * n, m)  # Iterator over every combination of indices of length m
        for combination in combinations
            board .= 0  # Clear the board
            board[combination] .= 1  # Place a checker on every part of the board specified by the combination of indices
            if covered(board)  # Check if the board is covered
                return (board, m)  # Return the solution if found
            end
        end
    end
    return (Bool[;;], 0)  # Return an empty board if no solution is found
end
```

## Stochastic Search
The stochastic search method improves upon the brute force search by iteratively moving a non-covered board closer to a covered board with the same number of checkers. It achieves this by finding the square with a checker that covers the fewest other squares and placing its checker on the square with the most uncovered squares around it.

The `update!` function moves a checker from a covering square to a hole, reducing the number of holes on the board.

```julia
function update!(A)
    (h, holeIndex) = findmax(neighbors(is_hole(A)))
    (c, tokenIndex) = find_min_covering(A)
    @assert A[holeIndex] == 0
    @assert A[tokenIndex] == 1
    A[holeIndex] = 1
    A[tokenIndex] = 0
    return A
end
```

Note that `find_min_covering` only needs to look at the squares with checkers on them.

This update algorithm can be run until the number of holes is 0.

```julia
function find_min_covering(A)
    I = filter(I -> A[I], CartesianIndices(A)) |> collect
    (c, II) = findmin(I -> covering(A, I), I)
    return (c, I[II])
end
```

The `stochastic_search` function applies the `update!` function iteratively until the number of holes is reduced to zero. However, it may encounter local minima where the algorithm oscillates between multiple boards with a non-zero number of holes. In such cases, the board can be shuffled to give the algorithm a new initial condition, and the process can be restarted.

```julia
using Random

function stochastic_search(
    n::Int,
    m::Int;
    init=reshape(shuffle(vcat(ones(Bool, m), zeros(Bool, n * n - m))), n, n),
    attempts=10^7,
    (update!)=update!
)
    A = copy(init)
    for _ in 1:attempts
        prev_holes = holes(A)
        update!(A)
        next_holes = holes(A)
        while next_holes > 0 && prev_holes > next_holes
            prev_holes = next_holes
            update!(A)
            next_holes = holes(A)
        end
        if holes(A) == 0
            return A
        end
        shuffle!(A)
    end
    return Bool[;;]
end
```

Note that `stochastic_search` can be used to find an upper bound on `m`, as higher values of `m` increase the likelihood of finding a solution. However, it cannot find a lower bound for `m` because it does not try all the boards exhaustively.

## Using CUDA
To accelerate the brute force search method, this project incorporates CUDA, a parallel computing platform and API model that enables programming GPUs. By utilizing GPU parallelism, the computation time can be significantly reduced for large board sizes.

To use CUDA in the brute force search method, the `brute_force` function can be modified to use CUDA arrays (`CuArray`) provided by the CUDA.jl package. Here's an example of how to modify the `brute_force` function to use CUDA:

```julia
using CUDA, Combinatorics

function brute_force(n, M=ceil(Int, n * n / 5):(n*n))
    board = CUDA.zeros(Bool, n, n)  # Use CuArray to allocate a GPU array
    for m in M
        combinations = Combinatorics.Combinations(n * n, m)  # Iterator over every combination of indices of length m
        for combination in combinations
            CUDA.@sync CUDA.@cuda threads=256 brute_force_kernel(board, combination)  # Launch the kernel on the GPU
            if CUDA.@sync covered(board)  # Check if the board is covered
                return (board, m)  # Return the solution if found
            end
        end
    end
    return (Bool

[;;], 0)  # Return an empty board if no solution is found
end

@cuda threads=256 function brute_force_kernel(board, combination)
    # Kernel code to place checkers on the board based on the combination of indices
    # ...
end
```

To utilize CUDA in the brute force search method, make sure to install the CUDA.jl package and have compatible CUDA-enabled hardware and drivers.

## Building and Running the Project
To build and run this Julia project, follow these steps:

1. Install Julia: Download and install Julia from the [official Julia website](https://julialang.org/downloads/). Follow the installation instructions specific to your operating system.

2. Set up CUDA (if using CUDA): If you plan to use CUDA for GPU acceleration, make sure to install CUDA drivers and set up the necessary environment variables. Refer to the CUDA.jl documentation for detailed instructions.

3. Set up the project: Create a new directory for your project and navigate to it using a terminal or command prompt. Initialize a new Julia project in this directory by running the following command:
   ```
   $ julia --project=.
   ```

4. Install project dependencies: To install the required packages for this project, run the following command in the Julia REPL (started from the project directory):
   ```julia
   using Pkg
   Pkg.activate(".")
   Pkg.add("Combinatorics")
   Pkg.add("CUDA")  # If using CUDA
   ```

5. Create the source files: Create a new file called `checkers.jl` and copy the code from the relevant sections above. Additionally, create a file called `tests.jl` and copy the provided test code into it.

6. Implement the modifications: Modify the `brute_force` function to use CUDA (if desired) and include the necessary CUDA kernel code. Add comments to the code and make any other desired changes.

7. Run the tests: To execute the tests, run the following command in the Julia REPL:
   ```julia
   include("tests.jl")
   ```

8. Build and run the project: Depending on your requirements, you can create a Julia script or application to utilize the `brute_force` or `stochastic_search` functions. Use the desired function and its arguments to solve the problem for specific board sizes.

By following these steps, you can build and run the Checkers.jl project, test the functionality of the solution methods, and explore CUDA acceleration if desired.
