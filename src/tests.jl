using Test
include("brute_force.jl")
using .BruteForce

function test_valid_solution()
	@test_throws MethodError valid_solution(-1, [true], (1,))
	@test_throws MethodError valid_solution(0, [true], (1,))
  @test valid_solution(1, [true], (1,))
  @test valid_solution(2, [false true; false false], (1,))
  @test valid_solution(2, [true false; false false], (2,))
end

function valid_solution(n, solution, expected)
    result = brute_force(n)
    @test result[1] == solution
    @test result[2] in expected
end

@testset "Brute Force Algorithm" begin
    @testset "Valid Solution" begin
        test_valid_solution()
    end
end
