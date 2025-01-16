
export auth_login
function auth_login(baseurl;username="admin",password=nothing,verbose=false)
    #=
        username="admin"
        pw = ENV["QBITTORRENT_PASSWORD"]
        password = pw
        auth_login(cfgs[1].url)
    =#
    pw = ""
    if isnothing(password)
        @assert haskey(ENV,"QBITTORRENT_PASSWORD") "QBITTORRENT_PASSWORD environment variable not set and password was not provided."
        pw = ENV["QBITTORRENT_PASSWORD"]
    else 
        pw = password
    end

    @assert !endswith(baseurl,"/") "baseurl must not end with a slash /"
    url = string(baseurl,"/api/v2/auth/login")
        
    #curl = CurlHTTP.CurlEasy(url=url,method=CurlHTTP.POST,verbose=true)
    curl = CurlHTTP.CurlEasy(url=url,method=CurlHTTP.POST,verbose=verbose)
    CurlHTTP.curl_easy_setopt(curl, CurlHTTP.CURLOPT_HTTP_VERSION, CurlHTTP.CURL_HTTP_VERSION_1_1) 
    #CurlHTTP.curl_easy_setopt(curl, CurlHTTP.CURLOPT_HTTP_VERSION, CurlHTTP.CURL_HTTP_VERSION_1_0)
    #CurlHTTP.curl_easy_setopt(curl, CurlHTTP.CURLOPT_HTTP_VERSION, CurlHTTP.CURL_HTTP_VERSION_2_0)
    
    requestBody = "username=$(username)&password=$(pw)"
    headers = ["Referer: $(baseurl)"]
    res, http_status, errormessage = CurlHTTP.curl_execute(curl, requestBody, headers)

    responseBody = String(curl.userdata[:databuffer])
    if responseBody != "Ok."
        @show responseBody
    end
    if responseBody == "Fails."
       throw(ErrorException("Wrong username or password."))
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

