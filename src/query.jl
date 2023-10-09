export stats
function stats(influxdbsettings)
    #di = Dict(Year(10) => "last_10 years",Year(1) => "last_year",Month(1)=>"last_month",Week(1)=>"last_week",Day(1)=>"last_day",Hour(12)=>"last_12 hours",Hour(6)=>"last_6 hours",Hour(1)=>"last_hour",Minute(30)=>"last_30 minutes",Minute(15)=>"last_15 minutes",Minute(5)=>"last_5 minutes",Minute(1)=>"last_minute")
    di = Dict(Year(1) => "last year",Month(1)=>"last_month",Week(1)=>"last_week",Day(1)=>"last_day",Hour(12)=>"last_12hours",Hour(6)=>"last_6hours",Hour(1)=>"last_hour")
    (k,v) = first(di)
    #=
        k,v=Year(1),"last_year"
        k,v=Day(1),"last_day"
        k,v=Week(1),"last_w"
        (k, v) = (Minute(15), "last_15 minutes")
    =#
    df = DataFrames.DataFrame()
    for (k,v) in di        
        df0 = stats_in_timerange(k,influxdbsettings)
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
        fsize = filesize(influxdbsettings)
        #join 
        DataFrames.leftjoin!(df,fsize,on=:name)
    
    ########################################################
    #add total 
    ########################################################
    nms = setdiff(names(df),["name"])
    df[!,:constant] .= 1
    tot = DataFrames.combine(DataFrames.groupby(df, :constant), nms .=> sum .=> nms)
    tot[!,:name] .= "Total"
    DataFrames.select!(tot,DataFrames.Not([:constant]))
    
    res = vcat(DataFrames.select(df,DataFrames.Not([:constant])),tot)

    return res
end

export stats_in_timerange
function stats_in_timerange(tr,influxdbsettings)
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

    qry = """
    First = from(bucket: "qBittorrentStats")
    |> range(start: $(rng))
    |> filter(fn: (r) => r["_field"] == "total_uploaded" or r["_field"] == "total_downloaded")
    |> first()    

    Last = from(bucket: "qBittorrentStats")
    |> range(start: $(rng))
    |> filter(fn: (r) => r["_field"] == "total_uploaded" or r["_field"] == "total_downloaded")
    |> last()  
    
    union(tables: [Last,First])
    |> sort(columns: ["_value"], desc: false)
    |> difference()
    |> drop(columns: ["hash", "_measurement","is_private"]) 
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
gb = DataFrames.groupby(df, [:name,:_field])
cmb = DataFrames.combine(gb, :_value => sum => :_value)
cmb2 = DataFrames.unstack(cmb, :name, :_field, :_value)
DataFrames.disallowmissing!(cmb2)
DataFrames.select!(cmb2,[:name,:total_uploaded,:total_downloaded])
DataFrames.rename!(cmb2,"total_downloaded"=>"GBdown","total_uploaded"=>"GBup")

return cmb2
end

export filesize 
function filesize(influxdbsettings)
qry = """from(bucket: "qBittorrentStats")
  |> range(start: -10y)  
  |> filter(fn: (r) => r["_field"] == "total_size")
  |> last()
  |> yield(name: "last")
  """

bdy = InfluxDBClient.query_flux(influxdbsettings,qry)
tz = Dates.TimeZone("Europe/Berlin")
df = InfluxDBClient.query_flux_postprocess_response(bdy,true,"s",tz)
DataFrames.select!(df,[:_value,:name])
#convert to gigabytes
df._value =  df._value ./ 1073741824.0
unique!(df,:name)
DataFrames.rename!(df,:_value=>:size_in_GB)

#cm = StatsBase.countmap(df.name)
#filter where n > 1 
#df = filter(x->cm[x.name] > 1,df)

return df
end
#=

tmp = filter(x->startswith(x.name,"Quantico.S02.COMPLETE.GERMAN"),df)

tmp = filter(x->startswith(x.name,"Transformers.Aufstieg.der.Bestien.2023.German.AC3.DL.1080p.BluRay.AVC.Remux-MAMA"),df)

=#