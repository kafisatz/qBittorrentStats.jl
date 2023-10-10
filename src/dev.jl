using Revise;using qBittorrentStats
import CurlHTTP;import HTTP;import JSON3;using DataFrames; using InfluxDBClient; using Dates
#baseurl = "http://qbittorrentdockervm.diro.ch" #apparrently TLS 1.3 causes issues...

baseurl = "http://10.14.15.205:8080"
influxdbbucketname = "qBittorrentStats"
influxdbsettings = InfluxDBClient.get_settings()

@time cookieDict = writestats(baseurl,influxdbbucketname,influxdbsettings)

di = Dict(Year(1)=>"lastYear")
@warn("Querying is NON-TRIVIAL in case torrents/files are deleted. Unclear if the results are correct for such cases.")
dfstats = stats(influxdbsettings,baseurl,di = di)

#filter for interesting bits 
data = filter(x->x.torrent_exists == 1,dfstats)
filter!(x->x.GBuplastYear <= 0,data)
sort!(data,:size_in_GB)

hpick = data[1,:hash]

#/api/v2/torrents/delete?hashes=8c212779b4abde7c6bc608063a0d008b7e40ce32&deleteFiles=false
