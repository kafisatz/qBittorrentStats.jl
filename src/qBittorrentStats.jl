module qBittorrentStats

import CurlHTTP
import HTTP
import JSON3
import DataFrames
import InfluxDBClient
using PyCall
using Dates

# Write your package code here.
include("webuiauth.jl")
include("webuiapi.jl")
include("influx.jl")
include("main.jl")
include("query.jl")
include("cleanup.jl")
include("disk_space.jl")

function __init__()
    py"""import shutil
    def pydiskspace(pt):
        print(pt)
        return shutil.disk_usage(pt)
    """    
return nothing 
end

end
