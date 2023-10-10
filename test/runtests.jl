using qBittorrentStats
using Test

@testset "qBittorrentStats.jl" begin
    # Write your tests here.

    include("webuiapi.jl")
    include("local_tests_wrapper.jl")
end
