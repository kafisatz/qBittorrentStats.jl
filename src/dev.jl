using Revise
using qBittorrentStats
import CurlHTTP 
import HTTP
import JSON3

#baseurl = "http://qbittorrentdockervm.diro.ch" #apparrently TLS 1.3 has issues...
baseurl = "http://10.14.15.205:8080"

@time cookie,cookieDict = auth_login(baseurl)
@time res = version(baseurl,cookieDict)
res = webapiVersion(baseurl,cookieDict)
@time js = gettorrents(baseurl,cookieDict);

h = js[1].hash
@time jsproperties = properties(baseurl,cookieDict,h);

@time jsproperties = properties(baseurl,cookieDict,map(x->x.hash,js));
size(jsproperties)
jsproperties[1]
#@show sort(collect(keys(js[1])))

println(c)