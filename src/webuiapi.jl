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
