@testset "local_tests_wrapper.jl" begin
    #these will only work if qBittorrent and InfluxDB are up and running 
    try 
        include("local_tests_writestats.jl")
    catch e 
        @show e
    end
    
end