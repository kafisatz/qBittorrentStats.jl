export auth_login
function auth_login(baseurl;username="admin",password=nothing)
    pw = ""
    if isnothing(password)
        @assert haskey(ENV,"QBITTORRENT_PASSWORD") "QBITTORRENT_PASSWORD environment variable not set and password was not provided."
        pw = ENV["QBITTORRENT_PASSWORD"]
    end

    @assert !endswith(baseurl,"/") "baseurl must not end with a slash /"
    url = string(baseurl,"/api/v2/auth/login")
    
    hdr = Dict("Referer" => baseurl)
    resp = HTTP.post(url, hdr, body="username=$(username)&password=$(pw)",redirect=true)


cookie="error"

return cookie

end