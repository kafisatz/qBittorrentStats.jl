export writestats 
function writestats(baseurl::String,influxdbbucketname::String,influxdbsettings::Dict{String,String};cookieDict=nothing,username="admin",password=nothing,uptimekumaurl="")
    try 
        return main_internal(baseurl,influxdbbucketname,influxdbsettings,cookieDict=cookieDict,username=username,password=password,uptimekumaurl=uptimekumaurl)
    catch e
        @show e
        return nothing
    end
end 

export main_internal 
function main_internal(baseurl::String,influxdbbucketname::String,influxdbsettings::Dict{String,String};cookieDict=nothing,username="admin",password=nothing,uptimekumaurl="",printtime=false)
    #=
        username = "admin"
        pw = ENV["QBITTORRENT_PASSWORD"]
        password = pw
    =#
    if printtime
        ts = string(round(Dates.now(Dates.TimeZone("Europe/Zurich")),Dates.Second))
        loc = findfirst("+",ts)
        if !isnothing(loc)
            ts2 = ts[1:loc[1]-1]
        else 
            ts2 = ts 
        end
        @info("Europe/Zurich now = $(ts2)")
    end

    if isnothing(cookieDict)
        cookie,cookieDict = auth_login(baseurl,username=username,password=password)
    end

    ##################################################################
    #check if webuiapi is enabled
    ##################################################################
        v = try
            version(baseurl,cookieDict)
        catch e
            @show e 
            cookie,cookieDict = auth_login(baseurl,username=username,password=password)
            @info("Retrying with a new cookie")
            version(baseurl,cookieDict)
        end
        #res should be something like "v4.5.5"
        @assert isa(v,String)
        @assert length(v) > 0

    #webapiv = webapiVersion(baseurl,cookieDict)

    ##################################################################
    #get list of torrents
    ##################################################################
    js = gettorrents(baseurl,cookieDict);
    #storing magnet URIs, this writes to a different measurement "$(baseurl)_magnetURIs"
    storemagneturis(js,influxdbsettings,baseurl,influxdbbucketname)

    #if there are no torrents, we are done
    if iszero(length(js))
        return cookieDict
    end

    ##################################################################
    #size and last actitivty
    ##################################################################
    #get size and last activity
    lastactivitydf = DataFrames.DataFrame(name=map(x->x.name,js),hash=map(x->x.hash,js),size=map(x->x.size,js),last_activity=map(x->x.last_activity,js),tracker=map(x->x.tracker,js),added_on=map(x->x.added_on,js))
    sort!(lastactivitydf,[:last_activity],rev=true)
    lastactivitydf.last_activity_dt = Dates.unix2datetime.(lastactivitydf.last_activity)
    lastactivitydf.added_on_dt = Dates.unix2datetime.(lastactivitydf.added_on)    
    
    lastactivitydf.sizegb = lastactivitydf.size ./ 1024 ./ 1024 ./ 1024
    #cumulate size
    lastactivitydf.sizegb_cumsum = cumsum(lastactivitydf.sizegb)
    lastactivitydf
    
    ##################################################################
    #get properties for each torrent
    ##################################################################
    hlist = map(x->x.hash,js);
    jsproperties = properties(baseurl,cookieDict,hlist);
    
    ##################################################################
    #Create DataFrame
    ##################################################################
    df = DataFrames.DataFrame(jsproperties)
    #add current timestamp (UTC)
    df[!,:datetime] .= Dates.now(Dates.UTC)
    #is private -> 1, else 0
    df[!,:is_private] .= ifelse.(df.is_private,1,0)
    tags = ["is_private","name","hash"]
    fields = ["addition_date","completion_date","seeding_time","share_ratio","time_elapsed","total_downloaded","total_downloaded_session","total_size","total_uploaded","total_uploaded_session"]
    DataFrames.select!(df,vcat("datetime",tags,fields))

    ##################################################################
    #Connect to InfluxDB
    ##################################################################
    local bucket_names 
    try
        bucket_names, json = InfluxDBClient.get_buckets(influxdbsettings);
    catch e
        @show e
        throw(ErrorException("Could not connect to InfluxDB."))
    end
    @assert in(influxdbbucketname,bucket_names) "Bucket $(influxdbbucketname) does not exist. Please create it."

    ##################################################################
    #write data to bucket. NOTE: we are using UTC timestamps
    ##################################################################    
    local rs 
    local lp 
    try
        rs,lp = InfluxDBClient.write_dataframe(settings=influxdbsettings,bucket=influxdbbucketname,measurement=baseurl,data=df,fields=fields,tags=tags,timestamp=:datetime);
    catch ef 
        @show ef 
    end

    if !in(rs,[200,204])
        @warn "Unexpected return value. Data may not have been written to InfluxDB" rs
    end

    #set uptimkuma status 
    if uptimekumaurl != ""
        HTTP.get(uptimekumaurl)
    end

    return cookieDict,lastactivitydf
end

export timestring 
function timestring()
    ts = string(round(Dates.now(Dates.TimeZone("Europe/Zurich")),Dates.Second))
    loc = findfirst("+",ts)
    if !isnothing(loc)
        ts2 = ts[1:loc[1]-1]
    else 
        ts2 = ts 
    end
    #@info("Europe/Zurich now = $(ts2)")
    return ts2  
end



export init_global_vars 
function init_global_vars() 
    baseurl = "http://10.14.15.205:8080"
    influxdbbucketname = "qBittorrentStats"
    influxdbsettings = InfluxDBClient.get_settings()
    uptimekumaurl = "https://uptimekuma.diro.ch/api/push/NVYbzSfPBb?status=up&msg=OK&ping=2" #optional

    #the script will not run without these
    @assert haskey(ENV,"INFLUXDB_URL")
    @assert haskey(ENV,"INFLUXDB_ORG")
    @assert haskey(ENV,"INFLUXDB_TOKEN")
    @assert haskey(ENV,"QBITTORRENT_PASSWORD")

    @assert ENV["INFLUXDB_URL"] != ""
    @assert ENV["INFLUXDB_ORG"] != ""
    @assert ENV["INFLUXDB_TOKEN"] != ""
    @assert ENV["QBITTORRENT_PASSWORD"] != ""

    @info("Testing InfluxDB access")
    try
        bucket_names, json = InfluxDBClient.get_buckets(influxdbsettings);
        @show bucket_names
    catch e
        @show e
        @warn("Failed to access InfluxDB. See above!")
    end



    hours_when_data_cleanup_has_run = []

    data_dirs = ["/volume2/data_ssd/downloads_torrent_clients/dockervm",raw"\\ds\data_ssd\downloads_torrent_clients\dockervm"]
    filter!(isdir,data_dirs)

    return baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl,data_dirs
    
    return nothing 
end