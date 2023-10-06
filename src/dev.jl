using Revise;using qBittorrentStats
import CurlHTTP;import HTTP;import JSON3;using DataFrames; using InfluxDBClient; using Dates
#baseurl = "http://qbittorrentdockervm.diro.ch" #apparrently TLS 1.3 causes issues...

baseurl = "http://10.14.15.205:8080"
influxdbbucketname = "qBittorrentStats"
influxdbsettings = InfluxDBClient.get_settings()

@time cookieDict = writestats(baseurl,influxdbbucketname,influxdbsettings)
#@time cookieDict = writestats(baseurl,influxdbbucketname,influxdbsettings)
