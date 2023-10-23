module qBittorrentStats

import CurlHTTP
import HTTP
import JSON3
import DataFrames
import InfluxDBClient
using Dates

# Write your package code here.
include("webuiauth.jl")
include("webuiapi.jl")
include("influx.jl")
include("main.jl")
include("query.jl")
include("cleanup.jl")

end
