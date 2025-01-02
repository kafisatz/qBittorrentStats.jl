@testset "local_tests_wrapper.jl" begin

    pt = pathof(qBittorrentStats)
    freediskspace(splitdir(pt)[1])
    @test true

end

