if !isdefined(Main, :__init__) || Base.function_module(__init__) != Checkers
	using Pkg
	Pkg.instantiate()
end

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

if !isdefined(Main, :__init__) || Base.function_module(__init__) != Checkers
	using .Checkers
	@info ARGS
	@time result = Checkers.Algorithems.brute_force(parse(Int,ARGS[1]))
	println(last(result))
	display(first(result))
end
