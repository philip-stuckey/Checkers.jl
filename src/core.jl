module CheckersCore

using CUDA

export Pad, getindex, eltype
export covered, neighbors

"""
I didn't want to deal with literal edge cases, so I made this wrapper struct
to return 0 when you try to index outside of the bounds of the matrix.
"""
struct Pad{T,A<:AbstractMatrix{T}}
    arr::A
    fill::T
end

Pad(arr::AbstractMatrix{T}) where {T} = Pad(arr, zero(T))

function Base.getindex(z::Pad{T}, i, j)::T where {T}
index = CartesianIndex(i, j)
indices = CartesianIndices(z.arr)::CartesianIndices{2,Tuple{Base.OneTo{Int64},Base.OneTo{Int64}}}
return (index in indices) ? z.arr[i, j] : z.fill
end

Base.getindex(z::Pad, c::CartesianIndex{2}) = getindex(z, Tuple(c)...)

"""
this function is helpful for type stability. Essentially it informs the
compiler that indexing a ZeroPad object will return the same type as the
underlying matrix.
"""
Base.eltype(::Type{Pad{T}}) where {T} = T

"""
get the Von Neumann neighborhood (of radius 1) around the (i, j)th element of
matrix x. Here is where we use Pad to avoid having to worry about indices
out of bounds.
"""
function neighbors(z::Pad, (i, j))
neighbors = CUDA.zeros(Int8, 5)
neighbors[1] = z[i-1, j]
neighbors[2] = z[i, j-1]
neighbors[3] = z[i, j+1]
neighbors[4] = z[i+1, j]
neighbors[5] = z[i, j]
return neighbors
end

function neighbors(z::Pad, I::CartesianIndex{2})
return neighbors(z, Tuple(I))
end

function neighbors(m::AbstractMatrix{T}, I; fill=zero(T)) where {T}
return neighbors(Pad(m, fill), I)
end

function neighbors(z::Pad)
    result = CUDA.zeros(Int, size(z.arr, 1) * size(z.arr, 2))
     function foo(result)
        idx = (blockIdx().x - 1) * blockDim().x + threadIdx().x
        if idx <= length(result)
            i, j = (idx - 1) ÷ size(z.arr, 2) + 1, (idx - 1) % size(z.arr, 2) + 1
            result[idx] = sum(neighbors(z, (i, j)))
        end
    end
    @cuda threads=length(result) blocks=1 foo()
    return result
end

function neighbors(m::AbstractMatrix{T}; fill=zero(T)) where {T}
return neighbors(Pad(m, fill))
end

"""
A matrix is "covered" if every element either is 1 or has a 1 in its
neighborhood.
"""
function covered(A)
return all(A .== 1 .| neighbors(A))
end

@warn "Lazy programmer warning: exporting all symbols"

end
