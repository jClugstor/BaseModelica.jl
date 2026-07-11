using SafeTestsets
using SciMLTesting

# Aqua/JET produce spurious reports on prerelease builds, so QA stays an
# explicit thunk to keep that guard. "Quality" is a legacy alias for QA.
function qa_group()
    isempty(VERSION.prerelease) || return nothing
    @safetestset "Quality Assurance" include(joinpath(@__DIR__, "qa", "qa.jl"))
    return nothing
end

run_tests(;
    core = function ()
        @safetestset "Julia Parser Tests" include("test_julia_parser.jl")
        @safetestset "ANTLR Parser Tests" include("test_antlr_parser.jl")
        return @safetestset "Error Message Tests" include("test_error_messages.jl")
    end,
    qa = (; env = joinpath(@__DIR__, "qa"), body = qa_group),
    umbrellas = Dict("Quality" => ["QA"]),
    # Original runtests ran QA/Quality only for those explicit GROUPs, never under
    # "All"; curate "All" to Core only to preserve that.
    all = ["Core"],
)
