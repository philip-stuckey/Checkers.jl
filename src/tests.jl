using Test
include("core.jl")
include("brute_force.jl")
using .BruteForce

# Function to validate the solution obtained from the brute_force function
function valid_solution(n, solution, expected)
    # Check if the obtained solution matches the expected solution
    board, m = brute_force(n)
    @test board == solution

    # Check if the correct error is thrown when using invalid arguments for brute_force and valid_solution functions
    @test_throws UndefVarError BruteForce.brute_force(1, 1:1)
    @test_throws MethodError valid_solution(1, [true], (1,))

    # Check if the valid_solution function returns the expected result for the given solution
    @test valid_solution(n, solution) == expected
end

# Test set for the brute_force function
@testset "Brute Force Algorithm" begin
    @test brute_force(1) == ([true], 1)  # Test for 1x1 board
    @test brute_force(2) == ([true false; true false], 2)  # Test for 2x2 board
    @test brute_force(3) == ([true false false; false false true; true false false], 3)  # Test for 3x3 board
end

# Test set for the valid_solution function
@testset "Valid Solution" begin
    valid_solution(1, [true], ([true], 1))  # Test for 1x1 board with expected solution
    valid_solution(2, [true false; true false], ([true false; true false], 2))  # Test for 2x2 board with expected solution
    valid_solution(3, [true false false; false false true; true false false], ([true false false; false false true; true false false], 3))  # Test for 3x3 board with expected solution
end
