export get_config 
function get_config(configfiles::Vector) 

    configfile = filter(isfiletry,configfiles)[1]
    @show configfile
    configfilehash = hash(read(configfile))
    cfgs = JSON3.read(configfile)
    #cfgs[2]

    for i in eachindex(cfgs)
        if cfgs[i].delete_torrents_without_data_and_data_without_torrents
            #data_dirs = ["/volume2/data_ssd/downloads_torrent_clients/dockervm",raw"\\ds\data_ssd\downloads_torrent_clients\dockervm"]
            data_dirs = cfgs[i].data_dirs
            @assert any(isdirtry,data_dirs)
        end

        if cfgs[i].delete_torrents_if_data_threshold_is_exceeded
            @assert cfgs[i].THRESHOLD_IN_TIB < 100
            @assert cfgs[i].THRESHOLD_IN_TIB > 0.1
        end
    end

    influxdbsettings = InfluxDBClient.get_settings()
    
    #=
        baseurl = "http://10.14.15.205:8080"
        influxdbbucketname = "qBittorrentStats"
        uptimekumaurl = "https://uptimekuma.diro.ch/api/push/NVYbzSfPBb?status=up&msg=OK&ping=2" #optional
    =#
    #the script will not run without these
    @assert haskey(ENV,"INFLUXDB_URL")
    @assert haskey(ENV,"INFLUXDB_ORG")
    @assert haskey(ENV,"INFLUXDB_TOKEN")
    @assert haskey(ENV,"QBITTORRENT_PASSWORD")

    @assert ENV["INFLUXDB_URL"] != ""
    @assert ENV["INFLUXDB_ORG"] != ""
    @assert ENV["INFLUXDB_TOKEN"] != ""
    @assert ENV["QBITTORRENT_PASSWORD"] != ""

    @info("Testing InfluxDB access")
    try
        bucket_names, json = InfluxDBClient.get_buckets(influxdbsettings);
        @show bucket_names
    catch e
        @show e
        @warn("Failed to access InfluxDB. See above!")
    end

    return cfgs,configfile,configfilehash,influxdbsettings
end

function get_config(x::String) 
    return get_config(vcat(x))
end

export rescan_config
function rescan_config(cfgs,configfile,configfilehash,influxdbsettings)
    @assert isfile(configfile)

    hash_current_file = hash(read(configfile))
    if configfilehash != hash_current_file
        println("################################!!################################")
        @info("config file has changed. Re-reading $configfile")
        println("################################!!################################")
        return get_config(configfile)
    else 
        return cfgs,configfile,configfilehash,influxdbsettings
    end
    
end