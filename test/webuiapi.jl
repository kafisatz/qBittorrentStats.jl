using Test 
using qBittorrentStats
import CurlHTTP
import HTTP
import JSON3

#at this point no tests are implemented
#for meaningful tests a qBittorrent instance and an InfluxDBClient are needed

@test true

@testset "webuiapi.jl" begin
    # Write your tests here.
    @test (1+1) == 2
end