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