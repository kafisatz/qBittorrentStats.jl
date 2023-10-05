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
    res = String(r.body)
    js = JSON3.read(res);
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

export auth_login
function auth_login(baseurl;username="admin",password=nothing)
    #=
        username="admin"
        pw = ENV["QBITTORRENT_PASSWORD"]
    =#
    pw = ""
    if isnothing(password)
        @assert haskey(ENV,"QBITTORRENT_PASSWORD") "QBITTORRENT_PASSWORD environment variable not set and password was not provided."
        pw = ENV["QBITTORRENT_PASSWORD"]
    end

    @assert !endswith(baseurl,"/") "baseurl must not end with a slash /"
    url = string(baseurl,"/api/v2/auth/login")

    curl = CurlHTTP.CurlEasy(url=url,method=CurlHTTP.POST,verbose=false)
    requestBody = "username=$(username)&password=$(pw)"
    headers = ["Referer: $(baseurl)"]
    res, http_status, errormessage = CurlHTTP.curl_execute(curl, requestBody, headers)

    responseBody = String(curl.userdata[:databuffer])
    if responseBody != "Ok."
        @show responseBody
    end
    @assert 200 == http_status
    responseHeaders = curl.userdata[:responseHeaders]
    
    @assert size(responseHeaders,1) > 1
    filter!(x->occursin("ookie: SID=",x),responseHeaders)
    @assert size(responseHeaders,1) == 1
    cookieraw = responseHeaders[1]
    startloc = findfirst("SID=",cookieraw)[1]
    cookieraw2 = cookieraw[startloc:end]
    endloc = findfirst(";",cookieraw2)[1]
    cookie = cookieraw2[1:endloc-1]

    #need --cookie "SID=6GHDs9Bskr3CWsSaM6kzMl+AuM+RWAEg"

    nm,val = split(cookie,"=")
    cookieDict = Dict(nm=>val)

return cookie,cookieDict

end
