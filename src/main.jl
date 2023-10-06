export writestats 
function writestats(baseurl::String,influxdbbucketname::String,influxdbsettings::Dict{String,String};cookieDict=nothing,username="admin",password=nothing)
    try 
        return main_internal(baseurl,influxdbbucketname,influxdbsettings,cookieDict=cookieDict,username=username,password=password)
    catch e
        @show e
        return nothing
    end
end

function main_internal(baseurl::String,influxdbbucketname::String,influxdbsettings::Dict{String,String};cookieDict=nothing,username="admin",password=nothing)
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

    #if there are no torrents, we are done
    if iszero(length(js))
        return cookieDict
    end

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
    rs,lp = InfluxDBClient.write_dataframe(settings=influxdbsettings,bucket=influxdbbucketname,measurement=baseurl,data=df,fields=fields,tags=tags,timestamp=:datetime);

    if !in(rs,[200,204])
        @warn "Unexpected return value. Data may not have been written to InfluxDB" rs
    end

    return cookieDict
end

