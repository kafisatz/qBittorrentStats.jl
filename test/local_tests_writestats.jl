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

@info("Testing writestats...")
#nsecsleep = 30*60
#while true
    @time cookieDict = writestats(baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl=uptimekumaurl)
    @test true
    sleep(0.5)
    @time cookieDict = writestats(baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl=uptimekumaurl)
    @test true
    sleep(0.5)
    @time cookieDict = writestats(baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl=uptimekumaurl)
    @test true
#end