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
    
    DataFrames.select!(df,keepnames)
    fixed_datetime = DateTime(Date(2020,1,1))
    df[!,:datetime] .= fixed_datetime
    tags = ["name","hash"]
    fields = setdiff(names(df),vcat(["datetime"],tags))
    try
        rs,lp = InfluxDBClient.write_dataframe(settings=influxdbsettings,bucket=influxdbbucketname,measurement=meas,data=df,fields=fields,tags=tags,timestamp=:datetime);
        return rs
    catch ef 
        @show ef 
    end    
    return nothing
end

export deletetorrent
function deletetorrent(h::String,baseurl::String;cookieDict=nothing,username="admin",password=nothing,deletefiles=true,verbose=false)
    #=
        username = "admin"
        pw = ENV["QBITTORRENT_PASSWORD"]
        password = pw
        deletefiles = true
    =#
    if isnothing(cookieDict)
        cookie,cookieDict = auth_login(baseurl,username=username,password=password)
    end

    #note: contrary to the webui documentation, this needs to be POST request
    url = baseurl * "/api/v2/torrents/delete"
    #bdy = Dict("deleteFiles"=>string(deletefiles),"hashes"=>h)
    #HTTP Post request are not working for some reason.....
    #r = HTTP.request("POST",url,[],bdy,cookies=cookieDict)
    
    #using CurlHTTP for now:
    curl = CurlHTTP.CurlEasy(url=url,method=CurlHTTP.POST,verbose=verbose) 
    CurlHTTP.curl_easy_setopt(curl, CurlHTTP.CURLOPT_HTTP_VERSION, CurlHTTP.CURL_HTTP_VERSION_1_1)
    
    requestBody = "hashes=$(h)&deleteFiles=$(deletefiles)"
    @assert length(cookieDict) == 1
    headers = ["Cookie: $(first(keys(cookieDict)))=$(first(values(cookieDict)))"]
    #requestBody = "{\"hashes\":\"$h\",\"deleteFiles\":$deletefiles}"
    #println(requestBody)
    
    res, http_status, errormessage = CurlHTTP.curl_execute(curl, requestBody, headers)
    @assert 200 == http_status "status was not 200 (deletetorrent)"
    return res 
end

