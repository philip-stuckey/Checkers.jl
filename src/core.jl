module CheckersCore

export Pad, getindex, eltype
export covered, covering
export is_hole, holes, neighbors

"""
I didn't want to deal with litteral edge cases, so I made this wrapper struct
to return 0 when you try to index outside of the bounds of the matrix.
"""
struct Pad{T,A<:AbstractMatrix{T}}
    arr::A
    fill::T
end

Pad(arr::AbstractMatrix{T}) where {T} = Pad(arr, zero(T))

"""
Check if the index is in the matrix bounds, if so, return the value of the 
matrix at that index, else return zero. 
e.g. 
```julia
x = ones(Bool, 10,10)
z = ZeroPad(x)
@assert z[10,10] == 1
@assert z[10,11] == 0
```
This function is strictly more complicated than it needs to be because I tried
to make it general for any abstract array, but then I gave up and made it work 
for only 2D arrays whose indices start at one. 
"""
function Base.getindex(z::Pad{T}, i, j)::T where {T}
    index = CartesianIndex(i, j)
    # The compiler couldn't infer the type of this variable, so I included this long and ponderous type assert
    indices = CartesianIndices(z.arr)::CartesianIndices{2,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}}}
    return (index in indices) ? z.arr[i, j] : z.fill
end

Base.getindex(z::Pad, c::CartesianIndex{2}) = getindex(z, Tuple(c)...)

"""
this function is helpful for type stability. Essentially it informs the 
compiler that indexing a `ZeroPad` object will return the same type as the
underlying matrix.
"""
Base.eltype(::Type{Pad{T}}) where {T} = T


"""
	get the Von Neuman neighborhood (of radius 1) around the i,jth element of 
matrix x. Here is where I use ZeroPad to avoiud having to worry about indicies
out of bounds.
"""
neighbors(z::Pad, (i, j)) = (z[i-1, j], z[i, j-1], z[i, j+1], z[i+1, j], z[i, j])
neighbors(z::Pad, I::CartesianIndex{2}) = neighbors(z, Tuple(I))
neighbors(m::AbstractMatrix{T}, I; fill=zero(T)) where {T} = neighbors(Pad(m, fill), I)

neighbors(z::Pad) = [sum(neighbors(z, Tuple(I))) for (I, a) in pairs(z.arr)]
neighbors(m::AbstractMatrix{T}; fill=zero(T)) where {T} = neighbors(Pad(m, fill))



holes(m::AbstractMatrix{T}; fill=zero(T)) where {T} = holes(Pad(m, fill))
holes(p::Pad) = sum(neighbors(p) .== 0)

is_hole(A) = [is_hole(A, I) for I in CartesianIndices(A)]
is_hole(A, I) = !covered(A, I)


"""
	A matrix is "covered" if every element either is 1 or has a 1 in it's 
neighborhood.
"""
covered(A) = all(covered(A, I) for I in CartesianIndices(A))
covered(A, I) = A[I] == 1 || 1 in neighbors(A, I)

covering(A, I) = A[I] * sum(neighbors(A, I, fill=one(eltype(A))) .== 0)

@warn "Lazy programmer warning: exporting all symbols"


end