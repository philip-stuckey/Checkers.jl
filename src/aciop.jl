#based on https://www.combinatorics.org/ojs/index.php/eljc/article/view/v18i1p141/pdf

vertex_order = Base.isless

struct SetDiff{A}
	V::A
end

"""
	"For a set S ⊆ V , the lexicographically smallest vertex in V \ S is denoted by s(S)."
"""
(s::SetDiff)(S) = minimum(setdiff(s.V, S))

