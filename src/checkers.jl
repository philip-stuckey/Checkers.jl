module Checkers


using Combinatorics

include("core.jl")

module Algorithems
    using Reexport

    include("brute_force.jl")
    @reexport using .BruteForce

    include("stochastic_search.jl")
    @reexport using .StochasticSearch
end

end
