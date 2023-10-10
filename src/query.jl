export stats
function stats(influxdbsettings,baseurl;di = Dict(Year(1) => "last year",Month(1)=>"last_month",Week(1)=>"last_week",Day(1)=>"last_day",Hour(12)=>"last_12hours",Hour(6)=>"last_6hours",Hour(1)=>"last_hour"))
    #di = Dict(Year(10) => "last_10 years",Year(1) => "last_year",Month(1)=>"last_month",Week(1)=>"last_week",Day(1)=>"last_day",Hour(12)=>"last_12 hours",Hour(6)=>"last_6 hours",Hour(1)=>"last_hour",Minute(30)=>"last_30 minutes",Minute(15)=>"last_15 minutes",Minute(5)=>"last_5 minutes",Minute(1)=>"last_minute")
    
    (k,v) = first(di)
    #=
        k,v=Year(1),"last_year"
        k,v=Day(1),"last_day"
        k,v=Week(1),"last_w"
        (k, v) = (Minute(15), "last_15 minutes")
    =#
    df = DataFrames.DataFrame()
    for (k,v) in di
        df0 = stats_in_timerange(k,influxdbsettings,baseurl)
        DataFrames.rename!(df0,"GBdown"=>"GBdown$(v)","GBup"=>"GBup$(v)")
        if size(df,1) == 0
            df = deepcopy(df0)
        else 
            #filter is only relvant if database changes between requests
            filter!(x->in(x.name,df.name),df0)
            #DataFrames.leftjoin(df,df0,on=:name)
            DataFrames.leftjoin!(df,df0,on=:name)
        end
    end
    DataFrames.disallowmissing!(df)

    #=
        df = dfstats
    =# 
    ########################################################
    #attach filesize 
    ########################################################
        fsize = filesizepertorrent(influxdbsettings,baseurl)
        #join
        DataFrames.leftjoin!(df,fsize,on=:name)
        DataFrames.disallowmissing!(df)
    
    ########################################################
    #add total 
    ########################################################
    nms = setdiff(names(df),["name","hash"])
    df[!,:constant] .= 1
    tot = DataFrames.combine(DataFrames.groupby(df, :constant), nms .=> sum .=> nms)
    tot[!,:name] .= "Total"
    tot[!,:hash] .= "Total"
    DataFrames.select!(tot,DataFrames.Not([:constant]))
    
    res = vcat(DataFrames.select(df,DataFrames.Not([:constant])),tot)

    return res
end

export stats_in_timerange
function stats_in_timerange(tr,influxdbsettings,baseurl)
    #=
        tr = Minute(93)
        tr = Hour(55)
        tr = Day(1)
        tr = Month(13)
        tr = Year(13)
        tr = k
    =#

    n_seconds = convert(Dates.Second, Dates.Millisecond(Dates.toms(tr)))
    if n_seconds.value <= 3600*72
        rng = "-$(n_seconds.value)s"
    else
        n_minutes = ceil(n_seconds,Dates.Minute(1))
        if n_minutes.value <= 60*24*14
            rng = "-$(n_minutes.value)m"
        else
            n_days = ceil(n_seconds,Dates.Day(1))
            rng = "-$(n_days.value)d"            
        end
    end

    baseurlquoted = "\"" * baseurl * "\""

    qry = """
    First = from(bucket: "qBittorrentStats")
    |> range(start: $(rng))
    |> filter(fn: (r) => r["_measurement"] == $(baseurlquoted))
    |> filter(fn: (r) => r["_field"] == "total_uploaded" or r["_field"] == "total_downloaded")
    |> first()    

    Last = from(bucket: "qBittorrentStats")
    |> range(start: $(rng))
    |> filter(fn: (r) => r["_measurement"] == $(baseurlquoted))
    |> filter(fn: (r) => r["_field"] == "total_uploaded" or r["_field"] == "total_downloaded")
    |> last()  
    
    union(tables: [Last,First])
    |> sort(columns: ["_value"], desc: false)
    |> difference()
    |> drop(columns: ["_measurement","is_private"]) 
    |> map(fn: (r) => ({r with _value: float(v: r._value) / 1073741824.0}))  
    |> drop(columns: ["_start", "_stop"])  
    |> group()  
    """

bdy = InfluxDBClient.query_flux(influxdbsettings,qry)
tz = Dates.TimeZone("Europe/Berlin")
df = InfluxDBClient.query_flux_postprocess_response(bdy,true,"s",tz)
DataFrames.select!(df,DataFrames.Not([:result,:table]))
unique!(df,[:_value,:_field,:name]) #unclear why we sometimes have duplicates....

#in certain cases, we still have duplicate entries for each name,_field combination (often with one entry "0.0 upload")
gb = DataFrames.groupby(df, [:name,:hash,:_field])
cmb = DataFrames.combine(gb, :_value => sum => :_value)
cmb2 = DataFrames.unstack(cmb, [:name,:hash], :_field, :_value)
#sort!(cmb2,:total_downloaded)
#sort!(cmb2,:total_uploaded)

#relace missing with zero 
cmb2[ismissing.(cmb2[:,:total_downloaded]), :total_downloaded] .= 0.0
cmb2[ismissing.(cmb2[:,:total_uploaded]), :total_uploaded] .= 0.0

DataFrames.disallowmissing!(cmb2)
DataFrames.select!(cmb2,[:name,:hash,:total_uploaded,:total_downloaded])
DataFrames.rename!(cmb2,"total_downloaded"=>"GBdown","total_uploaded"=>"GBup")

return cmb2
end

export filesizepertorrent 
function filesizepertorrent(influxdbsettings,baseurl)
    baseurlquoted = "\"" * baseurl * "\""
    qry = """from(bucket: "qBittorrentStats")
    |> range(start: -10y)
    |> filter(fn: (r) => r["_measurement"] == $(baseurlquoted))
    |> filter(fn: (r) => r["_field"] == "total_size")
    |> last()
    |> yield(name: "last")
    """

    bdy = InfluxDBClient.query_flux(influxdbsettings,qry)
    tz = Dates.TimeZone("Europe/Berlin")
    df = InfluxDBClient.query_flux_postprocess_response(bdy,true,"s",tz)
    DataFrames.select!(df,[:_value,:name,:hash])
    #convert to gigabytes
    df._value =  df._value ./ 1073741824.0
    unique!(df,:name)
    DataFrames.rename!(df,:_value=>:size_in_GB)

    #cm = StatsBase.countmap(df.name)
    #filter where n > 1 
    #df = filter(x->cm[x.name] > 1,df)

    te = torrentsexists(influxdbsettings,baseurl)
    DataFrames.leftjoin!(df,DataFrames.select(te,DataFrames.Not([:name])),on=:hash)
    df[ismissing.(df[:,:torrent_exists]), :torrent_exists] .= false
    DataFrames.disallowmissing!(df)

    DataFrames.select!(df,DataFrames.Not([:hash]))

return df
end

export torrentsexists
"""
Returns torrents/hashes which exist in qBittorrent
"""
function torrentsexists(influxdbsettings,baseurl)
#find most recent timestamp
    age_of_ts_in_seconds = mostrecenttimestamp(influxdbsettings,baseurl)
    n_seconds = age_of_ts_in_seconds + 60 #to be safe add 1 minute

    baseurlquoted = "\"" * baseurl * "\""
    qry = """from(bucket: "qBittorrentStats")
    |> range(start: -""" * "$n_seconds" * """s)
    |> filter(fn: (r) => r["_measurement"] == $(baseurlquoted))
    |> filter(fn: (r) => r["_field"] == "total_size")
    |> last()
    |> yield(name: "last")
    """

    bdy = InfluxDBClient.query_flux(influxdbsettings,qry)
    tz = Dates.TimeZone("Europe/Berlin")
    df = InfluxDBClient.query_flux_postprocess_response(bdy,true,"s",tz)
    DataFrames.select!(df,[:hash,:name])
    df[!,:torrent_exists] .= true
    
return df
end
#=

tmp = filter(x->startswith(x.name,"Quantico.S02.COMPLETE.GERMAN"),df)

tmp = filter(x->startswith(x.name,"Transformers.Aufstieg.der.Bestien.2023.German.AC3.DL.1080p.BluRay.AVC.Remux-MAMA"),df)

=#

export mostrecenttimestamp
function mostrecenttimestamp(influxdbsettings,baseurl)
    baseurlquoted = "\"" * baseurl * "\""
    qry = """data = from(bucket: "qBittorrentStats")
    |> range(start: -1w)  
    |> filter(fn: (r) => r["_measurement"] == $(baseurlquoted))
    |> filter(fn: (r) => r["_field"] == "total_uploaded")
    |> keep(columns: ["_time","_value"])
    |> sort(columns: ["_time"])    
    //|> group()
    |> last()
    |> yield()
"""

    bdy = InfluxDBClient.query_flux(influxdbsettings,qry)
    tz = Dates.TimeZone("Europe/Berlin")
    df = InfluxDBClient.query_flux_postprocess_response(bdy,true,"s",tz)

    ts = df[1,:_time]
    age_of_ts_in_seconds = round(Dates.now() - ts,Dates.Second).value

    return age_of_ts_in_seconds
end


export candidates_for_deletion
function candidates_for_deletion(influxdbsettings,baseurl,di)
    dfstats = stats(influxdbsettings,baseurl,di = di)
    #filter for interesting bits
    data = filter(x->x.torrent_exists == 1,dfstats)
    col = filter(x->startswith(x,"GBup"),names(data))
    @assert length(col) == 1
    filter!(x->x[col[1]] <= 0,data)
    sort!(data,:size_in_GB)
    return data,dfstats
end