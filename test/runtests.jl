using qBittorrentStats
using Test
using Dates
import InfluxDBClient

@testset "qBittorrentStats.jl" begin

    include("webuiapi.jl")

    include("local_tests_wrapper.jl")
    include("python.jl")
    include("main.jl")
end
