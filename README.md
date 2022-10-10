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