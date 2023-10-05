using Test 
using Revise
using qBittorrentStats
import CurlHTTP 
import HTTP
import JSON3

#baseurl = "http://qbittorrentdockervm.diro.ch" #apparrently TLS 1.3 has issues...
baseurl = "http://10.14.15.205:8080"

cookie,cookieDict = auth_login(baseurl)
@test cookie == "SID=$(cookieDict["SID"])"

res = webapiVersion(baseurl,cookieDict)
@time js = gettorrents(baseurl,cookieDict);

cookieDictdoesnotwork = Dict("SID"=>"1234567890")
@test_throws HTTP.Exceptions.StatusError version(baseurl,cookieDictdoesnotwork)

@test_throws ErrorException("Wrong username or password.") cookie,cookieDict = auth_login(baseurl,password="not_correct")