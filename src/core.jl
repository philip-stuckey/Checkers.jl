module CheckersCore
    using CUDA

    export neighbors, covered

    """
    neighbors_kernel!(result, arr, nrows, ncols)

    CUDA kernel function that calculates the number of neighboring cells with a value of `true`
    for each cell in the input array `arr`.

    Args:
    - `result`: The output array to store the computed neighbor counts.
    - `arr`: The input boolean array representing the game board.
    - `nrows`: The number of rows in the array.
    - `ncols`: The number of columns in the array.
    """
    function neighbors_kernel!(result, arr, nrows, ncols)
        idx = (blockIdx().x - 1) * blockDim().x + threadIdx().x
        if idx <= length(result)
            i, j = (idx - 1) ÷ ncols + 1, (idx - 1) % ncols + 1
            count = 0
            for di = max(i-1, 1):min(i+1, nrows)
                for dj = max(j-1, 1):min(j+1, ncols)
                    @inbounds count += arr[di, dj]
                end
            end
            result[idx] = count
        end
        return nothing
    end

    """
    neighbors(arr::CUDA.CuArray{Bool})

    Calculates the number of neighboring cells with a value of `true`
    for each cell in the input array `arr` using GPU acceleration.

    Args:
    - `arr`: The input boolean array representing the game board.

    Returns:
    - An integer array representing the number of neighbors for each cell.
    """
    function neighbors(arr::CUDA.CuArray{Bool})
        nrows, ncols = size(arr, 1), size(arr, 2)
        result = CUDA.zeros(Int, nrows * ncols)
        @cuda threads=ceil(Int, (nrows*ncols)/1024) neighbors_kernel!(result, arr, nrows, ncols)
        return result
    end

    """
    covered(A::CUDA.CuArray{Bool})

    Checks if all cells in the input array `A` are covered.

    Args:
    - `A`: The input boolean array representing the game board.

    Returns:
    - `true` if all cells are covered, `false` otherwise.
    """
    function covered(A::CUDA.CuArray{Bool})
        nrows, ncols = size(A, 1), size(A, 2)
        result = CUDA.zeros(Bool, nrows, ncols)
        @cuda threads=ceil(Int, (nrows*ncols)/1024) covered_kernel!(result, A, nrows, ncols)
        return all(result)
    end

    """
    covered_kernel!(result, arr, nrows, ncols)

    CUDA kernel function that checks if each cell in the input array `arr` is covered.

    Args:
    - `result`: The output boolean array to store the coverage status.
    - `arr`: The input boolean array representing the game board.
    - `nrows`: The number of rows in the array.
    - `ncols`: The number of columns in the array.
    """
    function covered_kernel!(result, arr, nrows, ncols)
        idx = (blockIdx().x - 1) * blockDim().x + threadIdx().x
        if idx <= nrows * ncols
            i, j = (idx - 1) ÷ ncols + 1, (idx - 1) % ncols + 1
            result[idx] = arr[i, j] == 1
        end
        return nothing
    end
end
