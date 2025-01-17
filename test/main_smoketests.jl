@testset "main_smoketest.jl" begin
    
    configfiles = [raw"\\10.14.15.10\data\configs\qbittorrentstats\config.json",raw"\\ds\data\configs\qbittorrentstats\config.json","/volume1/data/configs/qbittorrentstats/config.json","/cfgfolder/qbittorrentstats/config.json"]
    @test any(isfiletry.(configfiles))

    cfgs,configfile,configfilehash,influxdbsettings = get_config(configfiles)
    @test size(cfgs,1) > 0

    for i in eachindex(cfgs)
        cfg = cfgs[i]
        monitor_instance(cfg)
        cfgs,configfile,configfilehash,influxdbsettings = rescan_config(cfgs,configfile,configfilehash,influxdbsettings);
        @test true
    end

end