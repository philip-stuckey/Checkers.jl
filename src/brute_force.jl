module BruteForce
using Combinatorics
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
    board = zeros(Bool, n, n)  # pre-allocate a board
    combinations = Combinatorics.Combinations(n * n, 0)
    for m in M
        combinations.k = m
        for combination in combinations  # most of the allocations happen here
            @views begin
                board .= 0  # Start by clearing the old board, this doesn't allocate
                board[combination] .= 1  # put a 1 on every part of the board specified by that combination of indices. This allocates a little bit
                if covered(board)  # check if the board is covered. This doesn't allocate somehow
                    return (board, m)  # if we find any solution, return early 
                end
            end
        end
    end
    return (Bool[;;], 0)  # if the function gets this far, presumably no solutions exist
end

function num_solutions(n, m)
    board = zeros(Bool, n, n)  # pre-allocate a board
    combinations = Combinatorics.Combinations(n * n, m)
    result = 0
    for combination in combinations  # most of the allocations happen here
        @views begin
            board .= 0  # Start by clearing the old board, this doesn't allocate
            board[combination] .= 1  # put a 1 on every part of the board specified by that combination of indices. This allocates a little bit
            if covered(board)  # check if the board is covered. This doesn't allocate somehow
                result += 1
            end
        end
    end
    return result
end

end
