
export monitor_instance
function monitor_instance(cfg)
    #cfg = cfgs[2]
    #cfg = cfgs[3]
    #cfg = cfgs[4]
    baseurl = cfg.url
    uptimekumaurl = cfg.uptimekumaurl
    THRESHOLD_IN_TIB = cfg.THRESHOLD_IN_TIB
    data_dirs = cfg.data_dirs
    
    #print information
    println("#"^200)
    ts,ts3 = timestring()
    #ts3 = "Europe/Zurich now = $(ts2)"
    
    password = nothing
    if haskey(cfg,"password") 
        if cfg.password != ""
            password = cfg.password
        end
    end

    #get data from qbittorrent
    lastactivitydf,js,cookieDict = getstats(baseurl,uptimekumaurl=uptimekumaurl,password=password);

    #currently disabled
    if false
        #this may error if the retention policy is finite, need to find out why though....  
        writestats(baseurl,lastactivitydf,js,influxdbbucketname,influxdbsettings,cookieDict=cookieDict,password=password)
    end

    tb_mean_over_last_n_days,ntorrents_mean_over_last_n_days,n_days,sizetb_vec = daily_volume(lastactivitydf)
    
    ntorrents = size(lastactivitydf,1)

    #cross seeds only need space 'once' per torrent name!
    space_usage_tib = round(sum(select(unique(lastactivitydf,:name),Not(:sizegb_cumsum)).sizegb)/1024, digits = 2)
    #sum(lastactivitydf.sizegb)/1024 #overstates true space usage

    #print basic information
        baseurl_info = replace(baseurl,".diro.ch"=>"")
        baseurl_info = replace(baseurl_info,"https://"=>"")
        baseurl_info = replace(baseurl_info,"http://"=>"")
        println(baseurl_info * " - " * ts3 * " - Number of torrents: $(ntorrents)")

    if cfg.delete_torrents_if_data_threshold_is_exceeded
        ndeleted = delete_torrents_if_data_threshold_is_exceeded(baseurl_info,baseurl,cookieDict,lastactivitydf,threshold_in_tb=THRESHOLD_IN_TIB,password=password)
        space_left_tib_until_torrent_pruning_starts = round(THRESHOLD_IN_TIB .- space_usage_tib,digits=2)
    else 
        ndeleted = 0
        space_left_tib_until_torrent_pruning_starts = 9999.9
    end

    if cfg.delete_torrents_without_data_and_data_without_torrents
    #################################################################################
    #clean up data (torrents without data are deleted & folders/files without torrent are also deleted)
        if (size(data_dirs,1) > 0)
            dir = filter(isdirtry,data_dirs)[1]
            if isdirtry(dir)
                if ndeleted != 0 
                    #MUST re fetch lastactivitydf (this is a MUST, as we just deleted torrents on disk and in the qbittorrent application)
                    lastactivitydf,js,cookieDict = getstats(baseurl,uptimekumaurl=uptimekumaurl,password=password);
                end

                delete_torrents_without_data_and_data_without_torrents_fn(baseurl,dir,lastactivitydf,cookieDict,password=password)
            #delete_torrents_without_data_and_data_without_torrents_fn(baseurl,dir,lastactivitydf,cookieDict;ntorrents_to_delete_threshold=10,data_to_delete_without_torrent_threshold_tib=1.0)
            end
        end
    end

    println("$(baseurl_info) - tb_mean_over_last_n_days = $(tb_mean_over_last_n_days) TiB - ntorrents_mean_over_last_n_days = $(ntorrents_mean_over_last_n_days) - n_days = $(n_days) - sizetb_vec = $(sizetb_vec)")
    #@show tb_mean_over_last_n_days,ntorrents_mean_over_last_n_days,n_days
    msg = "$(baseurl_info) - Nb. of deleted Torrents = $(ndeleted) - space used = $(space_usage_tib) TiB - space left until pruning = $(space_left_tib_until_torrent_pruning_starts) TiB - threshold = $(THRESHOLD_IN_TIB) TiB"
    println(msg)

return nothing 
end

export getstats
function getstats(baseurl::String;cookieDict=nothing,username="admin",password=nothing,uptimekumaurl="",printtime=false)
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
        try 
            cookie,cookieDict = auth_login(baseurl,username=username,password=password)
        catch e 
            @warn("this should not happen!")
            @show e
            cookie,cookieDict = auth_login(baseurl,username=username,password=password,verbose=true)
        end
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
    #size and last actitivty
    ##################################################################
    #get size and last activity
    lastactivitydf = DataFrames.DataFrame(name=map(x->x.name,js),hash=map(x->x.hash,js),size=map(x->x.size,js),last_activity=map(x->x.last_activity,js),tracker=map(x->x.tracker,js),added_on=map(x->x.added_on,js),downloaded=map(x->x.downloaded,js),uploaded=map(x->x.uploaded,js),ratio=map(x->x.ratio,js))
    sort!(lastactivitydf,[:added_on],rev=true)
    lastactivitydf.last_activity_dt = Dates.unix2datetime.(lastactivitydf.last_activity)
    lastactivitydf.added_on_dt = Dates.unix2datetime.(lastactivitydf.added_on)    
    
    lastactivitydf.sizegb = lastactivitydf.size ./ 1024 ./ 1024 ./ 1024
    lastactivitydf.downloadedgb = lastactivitydf.downloaded ./ 1024 ./ 1024 ./ 1024
    lastactivitydf.uploadedgb = lastactivitydf.uploaded ./ 1024 ./ 1024 ./ 1024
    #cumulate size
    lastactivitydf.sizegb_cumsum = cumsum(lastactivitydf.sizegb)
    lastactivitydf
    
     #set uptimkuma status 
    if uptimekumaurl != ""
        HTTP.get(uptimekumaurl)
    end

    return lastactivitydf,js,cookieDict
end

export writestats 
function writestats(baseurl,lastactivitydf,js,influxdbbucketname::String,influxdbsettings::Dict{String,String};cookieDict=nothing,username="admin",password=nothing,printtime=false)
    #=
        username = "admin"
        pw = ENV["QBITTORRENT_PASSWORD"]
        password = pw
    =#

    #storing magnet URIs, this writes to a different measurement "$(baseurl)_magnetURIs"
    storemagneturis(js,influxdbsettings,baseurl,influxdbbucketname)

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

   
    return nothing
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

    ts2b = deepcopy(ts2)
    #remove seconds 
    loc = findlast(":",ts2)
    ts2b = ts2b[1:loc[1]-1]
    ts2b = replace(ts2b,"T"=>" ")

    return ts2,ts2b
end

export smoketests
function smoketests(cfgs,configfile,configfilehash,influxdbsettings) 

    #run one without try catch (smoke tests)
    println("#"^200)
    println("#"^200)
    println("SMOKE TESTS")
    for i in eachindex(cfgs)
        cfg = cfgs[i]
        monitor_instance(cfg)
        cfgs,configfile,configfilehash,influxdbsettings = rescan_config(cfgs,configfile,configfilehash,influxdbsettings);
    end
    println("#"^200)
    println("SMOKE TESTS finished")
    println("#"^200)
    println("#"^200)
    println("")
    println("")
    println("")
    return true 
end

#=
efi = raw"C:\temp\ladf.csv" 
using CSV
CSV.write(efi,lastactivitydf)
=#