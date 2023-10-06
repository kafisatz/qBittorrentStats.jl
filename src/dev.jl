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

nms = sort(collect(keys(jsproperties[1])))
nms_interest = ["addition_date","completion_date","hash","is_private","name","seeding_time","share_ratio","time_elapsed","total_downloaded"," total_downloaded_session"," total_size","total_uploaded","total_uploaded_session"]
#add double quotes to above line 


cookieDictdoesnotwork = Dict("SID"=>"1234567890")
@time res = version(baseurl,cookieDictdoesnotwork)