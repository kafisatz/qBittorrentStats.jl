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

THRESHOLD_IN_TB = 15 #we are currently using the SSD volume (space is limited!)

nsecsleep = 10*60
while true
    try
        @time cookieDict,lastactivitydf = writestats(baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl=uptimekumaurl)
        ntorrents = size(lastactivitydf,1)
        space_usage_tib = round(maximum(lastactivitydf.sizegb_cumsum)/1024, sigdigits = 6)
        @time ndeleted = cleanup(baseurl,cookieDict,lastactivitydf,threshold_in_tb=THRESHOLD_IN_TB)
        if iszero(ndeleted)
            @info("No torrents were deleted (THRESHOLD_IN_TB=$(THRESHOLD_IN_TB)). space_usage_tib = $(space_usage_tib) TiB - Number of torrents: $(ntorrents)")
        else
            @info("$(ndeleted) torrents deleted (THRESHOLD_IN_TB=$(THRESHOLD_IN_TB)). space_usage_tib = $(space_usage_tib) TiB - Number of torrents: $(ntorrents)")
        end
    catch er
        @show er
    end
    sleep(nsecsleep)
end