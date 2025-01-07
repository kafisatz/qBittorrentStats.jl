using Pkg
Pkg.activate(".")
Pkg.instantiate()

#using Revise
using Dates; using DataFrames
using qBittorrentStats;import InfluxDBClient
#import CurlHTTP;import HTTP;import JSON3;using DataFrames;
#baseurl = "http://qbittorrentdockervm.diro.ch" #apparrently TLS 1.3 causes issues...

baseurl = "http://10.14.15.205:8080"
influxdbbucketname = "qBittorrentStats"
influxdbsettings = InfluxDBClient.get_settings()
uptimekumaurl = "https://uptimekuma.diro.ch/api/push/NVYbzSfPBb?status=up&msg=OK&ping=2" #optional

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

THRESHOLD_IN_TIB = 30.5 #we are currently using the SSD volume (space is limited!)

nsecsleep = 10*60
while true
    try
        #this may error if the retention policy is finite, need to find out why though....
        cookieDict,lastactivitydf = writestats(baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl=uptimekumaurl)
        ntorrents = size(lastactivitydf,1)
        
        #cross seeds only need space 'once' per torrent name!
        space_usage_tib = round(sum(select(unique(lastactivitydf,:name),Not(:sizegb_cumsum)).sizegb)/1024, digits = 2)
        #sum(lastactivitydf.sizegb)/1024 #overstates true space usage
        
        ndeleted = cleanup(baseurl,cookieDict,lastactivitydf,threshold_in_tb=THRESHOLD_IN_TIB)
        space_left_tib_until_torrent_pruning_starts = round(THRESHOLD_IN_TIB .- space_usage_tib,digits=2)

        ts2 = timestring()
        ts3 = "Europe/Zurich now = $(ts2)"

        msg = "THRESHOLD_IN_TIB = $(THRESHOLD_IN_TIB) TiB - space_usage_tib = $(space_usage_tib) TiB - space_left_tib_until_torrent_pruning_starts = $(space_left_tib_until_torrent_pruning_starts) TiB - Number of torrents: $(ntorrents) - " * ts3
        if iszero(ndeleted)
            @info("Nothing was deleted. " * msg)
        else
            s = ndeleted > 1 ? "s" : ""
            @info("$(ndeleted) torrent$(s) deleted.       " * msg)
        end
    catch er
        @show er
    end
    sleep(nsecsleep)
end

#=
    dir=raw"\\ds\data_ssd\downloads_torrent_clients\dockervm"    
    @time cookieDict,lastactivitydf = writestats(baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl=uptimekumaurl)
    delete_torrents_without_data(dir,lastactivitydf)
=#