using Test 
using Revise
using qBittorrentStats
import CurlHTTP
import HTTP
import JSON3

#at this point no tests are implemented
#for meaningful tests a qBittorrent instance and an InfluxDBClient are needed
 
@test true

@testset "webuiapi.jl" begin
    # Write your tests here.
    @test 1+1=2
end 

if false
    #baseurl = "http://qbittorrentdockervm.diro.ch" #apparrently TLS 1.3 has issues...
    baseurl = "http://10.14.15.205:8080"

    cookie,cookieDict = auth_login(baseurl)
    @test cookie == "SID=$(cookieDict["SID"])"

    res = webapiVersion(baseurl,cookieDict)
    @time js = gettorrents(baseurl,cookieDict);

    cookieDict = Dict("SID"=>"1234567890")
    @test_throws HTTP.Exceptions.StatusError version(baseurl,cookieDict)

    @test_throws ErrorException("Wrong username or password.") cookie,cookieDict = auth_login(baseurl,password="not_correct")
end