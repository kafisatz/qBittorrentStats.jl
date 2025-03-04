module qBittorrentStats

import CurlHTTP
import HTTP
import JSON3
using DataFrames
import InfluxDBClient
using PyCall
import StatsBase
using Dates

# Write your package code here.
include("webuiauth.jl")
include("webuiapi.jl")
include("influx.jl")
include("main.jl")
include("query.jl")
include("cleanup.jl")
include("disk_space.jl")
include("filesystem.jl")
include("config.jl")

function __init__()
    py"""import shutil
    import os
        
    def pydiskspace(pt):
        print(pt)
        return shutil.disk_usage(pt)

    def get_fs_freespace(pathname):
        "Get the free space of the filesystem containing pathname"
        stat= os.statvfs(pathname)
        # use f_bfree for superuser, or f_bavail if filesystem
        # has reserved space for superuser
        return stat.f_bfree*stat.f_bsize
    """
return nothing 
end

end
