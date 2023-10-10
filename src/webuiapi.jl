export properties 
function properties(baseurl,cookieDict,h::String)
    #https://qbittorrentdockervm.diro.ch/api/v2/torrents/properties?hash=dfbb3c3477240bb043855b0320f205abaf10a3ac
    urlwithhash = baseurl * "/api/v2/torrents/properties?hash=" * h
    r = HTTP.request("GET",urlwithhash,cookies=cookieDict);
    js = JSON3.read(r.body);
    return js
end

function properties(baseurl,cookieDict,h::Vector{String})
    return map(x->properties(baseurl,cookieDict,x),h)
end
 
export gettorrents
function gettorrents(baseurl,cookieDict)
    url = string(baseurl,"/api/v2/torrents/info")
    r = HTTP.request("GET",url,cookies=cookieDict);
    #res = String(r.body)
    js = JSON3.read(r.body);
    return js
end

export webapiVersion
function webapiVersion(baseurl,cookieDict)
    url = string(baseurl,"/api/v2/app/webapiVersion")
    r = HTTP.request("GET",url,cookies=cookieDict);
    res = String(r.body)
    return res 
end

export version
function version(baseurl,cookieDict)
    url = string(baseurl,"/api/v2/app/version")
    r = HTTP.request("GET",url,cookies=cookieDict);
    res = String(r.body)
    return res 
end 

export storemagneturis
function storemagneturis(js,influxdbsettings,baseurl,influxdbbucketname)
    #let us store all mangnet URIs in a separate measurement
    meas = baseurl * "_magnetURIs"

    #@show js[1]
    keepnames = ["name","hash","infohash_v2","magnet_uri","last_activity","size","total_size","tracker","trackers_count"]
    df = DataFrames.DataFrame(js)
    
    select!(df,keepnames)
    fixed_datetime = DateTime(Date(2020,1,1))
    df[!,:datetime] .= fixed_datetime
    tags = ["name","hash"]
    fields = setdiff(names(df),vcat(["datetime"],tags))
    rs,lp = InfluxDBClient.write_dataframe(settings=influxdbsettings,bucket=influxdbbucketname,measurement=meas,data=df,fields=fields,tags=tags,timestamp=:datetime);
    return rs
end

export deletetorrent
function deletetorrent()
    @error("in the works")    
    return res 
end