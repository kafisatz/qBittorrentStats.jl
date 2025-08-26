using Pkg;
Pkg.activate("."); Pkg.instantiate()
using Dates; using DataFrames; using StatsBase; using qBittorrentStats;import InfluxDBClient; import JSON3; import CurlHTTP;

function main_fn()
    configfiles = [raw"\\10.14.15.10\data\configs\qbittorrentstats\config.json",raw"\\ds\data\configs\qbittorrentstats\config.json","/volume1/data/configs/qbittorrentstats/config.json","/cfgfolder/qbittorrentstats/config.json"]
    @assert any(isfiletry.(configfiles))

    cfgs,configfile,configfilehash,influxdbsettings = get_config(configfiles)
    #cfgs,configfile,configfilehash,influxdbsettings = rescan_config(cfgs,configfile,configfilehash,influxdbsettings)
    #i=4
    @assert smoketests(cfgs,configfile,configfilehash,influxdbsettings)

    nsecsleep = 10*60
    while true
        for i in eachindex(cfgs)
            try
                cfg = cfgs[i]
                monitor_instance(cfg)
                cfgs,configfile,configfilehash,influxdbsettings = rescan_config(cfgs,configfile,configfilehash,influxdbsettings);
            catch er
                @show er
            end
        end
        sleep(nsecsleep)
    end

    return nothing 
end

main_fn()
