using Pkg
Pkg.activate(".")
Pkg.instantiate()

#using Revise; 
using Dates
using qBittorrentStats;import InfluxDBClient
#import CurlHTTP;import HTTP;import JSON3;using DataFrames; ; 
#baseurl = "http://qbittorrentdockervm.diro.ch" #apparrently TLS 1.3 causes issues...

baseurl = "http://10.14.15.205:8080"
influxdbbucketname = "qBittorrentStats"
influxdbsettings = InfluxDBClient.get_settings()
uptimekumaurl = "https://uptimekuma.diro.ch/api/push/NVYbzSfPBb?status=up&msg=OK&ping=2" #optional

nsecsleep = 60
while true 
    @time cookieDict = writestats(baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl=uptimekumaurl)
    sleep(nsecsleep)
end