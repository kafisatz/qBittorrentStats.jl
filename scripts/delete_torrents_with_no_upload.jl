using Revise;using qBittorrentStats
import CurlHTTP;import HTTP;import JSON3;using DataFrames; using InfluxDBClient; using Dates
baseurl = "http://10.14.15.205:8080"; influxdbbucketname = "qBittorrentStats"; influxdbsettings = InfluxDBClient.get_settings()
@time cookieDict,lastactivitydf = writestats(baseurl,influxdbbucketname,influxdbsettings)

@warn("Querying is NON-TRIVIAL in case torrents/files are deleted. Unclear if the results are correct for such cases.")
di = Dict(Minute(2)=>"last2m")
di = Dict(Year(1)=>"lastYear")
data,dfstats = candidates_for_deletion(influxdbsettings,baseurl,di)
size(dfstats,1),size(data,1)
@show data[1:3,:]
hpick = data[1,:hash]
npick = data[1,:name]
h = hpick

if false 
    #delete this pick
    rs = deletetorrent(h,baseurl,cookieDict=cookieDict,deletefiles=true)
    #it is best to 'write stats' after deleting a torrent. As the above query 'stats' will then not include the deleted torrent.
    @time cookieDict,lastactivitydf = writestats(baseurl,influxdbbucketname,influxdbsettings)
end