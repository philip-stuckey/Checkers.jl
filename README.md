# Checkers.jl
finding the size of the minimum dominating set of an n by n grid graph

Note that this was not the language I used to describe the problem when I 
started looking at this problem. I wanted to know what was the smallest number
of checkers (m) that I could use to cover a (n by n) checkerboard where a square is 
"covered" if it has a checker on it or is directly next to a square with a 
checker on it (diagonals don't count).

Note that m ≧ n²/5, because each individual checker can cover, at most, 5 squares. 
Also, m < n²/2, because a board that has a checker on every other square is 
covered (very inefficiently).

## usefull deffinitions

The Von Neuman neighborhood (of radius 1) around the i,jth element of 
matrix x. `z` here is a special matrix type that returns a default fill value
if any of the indices are out of bounds.

```julia
neighbors(z, (i, j)) = (z[i-1, j], z[i, j-1], z[i, j+1], z[i+1, j], z[i, j])
```

A square is "covered" if it has a checker on it (represented by a `1`) or is 
next to a square with a checker on it. 

```julia
covered(A, (i,j)) = A[i,j] == 1 || 1 in neighbors(A, (i,j))
```

if all squares on the board are covered, the whole board is also covered
```julia
covered(A) = all(covered(A, I) for I in CartesianIndices(A))
```

A "hole" is a square which is not covered
```julia
is_hole(A, I) = !covered(A, I)
is_hole(A) = [is_hole(A, I) for I in CartesianIndices(A)]
```

The number of squares a square is "covering" can be defined as
```julia
neighbors(m::AbstractMatrix, I; fill) = neighbors(Pad(m, fill), I)
covering(A, I) = A[I] * count(==(0), neighbors(A, I, fill=one(eltype(A))))
```

This uses a special overload of neighbors which counts all squares out of 
bounds as 1's instead of zeros. Otherwise checkers on the edge would "cover" 
squares which are outside of the board.

## By brute force search
The brute force search is simple and guareteed to give a minimal solution, but
performs horribly as n gets large due to the size of the search space 
increasing factorially. 

```julia
using Combinatorics
function brute_force(n, M=ceil(Int, n * n / 5):(n*n))
    board = zeros(Bool, n, n)  # pre-allocate a board
    for m in M
        # make an iterator over every combination of indices length m. These is where we'll put the 1s
        combinations = Combinatorics.Combinations(n * n, m)
        for combination in combinations  # most of the allocations happen here
            board .= 0  # Start by clearing the old board, this doesn't allocate
            board[combination] .= 1  # put a 1 on every part of the board specified by that combination of indices.
            if covered(board)  # check if the board is covered. This doesn't allocate somehow
                return (board, m)  # if we find any solution, return early 
            end
        end
    end
    return (Bool[;;], 0)  # if the function gets this far, presumably no solutions exist
end
```
This function starts at the smallest possible `m` and only increments `m` when
all boards have been exhausted. This means that the first covered board that
this function finds *must* be a minimal covering board, and therefore the 
function returns it immediatly. This is helpful because it doesn't require 
searching through the entire search space.

One issue with this function is that, due to how uses the same memory for every
board, it is not clear how to parallelize it.

## By Stochastic search. 

The way that the brute force search looks for covered boards is far from optimal, checking huge swaths
of uncovered boards before reaching any covered ones. Instead, why find a way to take a non-covered board
and move it *closer* to a covered board with the same number of checkers. One way to do this is to find the square
with a checker on it which coveres the fewest other squares, put it's checkeron the square with the most un-covered 
squares (called "holes") around it.

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

```julia
function find_min_covering(A)
    I = filter(I -> A[I], CartesianIndices(A)) |> collect
    (c, II) = findmin(I -> covering(A, I), I)
    return (c, I[II])
end
```

Note that `find_min_covering` only needs to look at the squares with checkers on them.
