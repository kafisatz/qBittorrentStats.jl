#
export upload_by_torrent
function upload_by_torrent(timerange)
qry = """
import "math"

First = from(bucket: "qBittorrentStats")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_field"] == "total_uploaded")
  //|> drop(columns: ["hash", "_measurement","is_private"])    
  |> first()  
  //|> yield(name:"First")  

Last = from(bucket: "qBittorrentStats")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_field"] == "total_uploaded")  
  //|> drop(columns: ["hash", "_measurement","is_private"])    
  |> last()
  //|> yield(name:"Last")
  
union(tables: [Last,First])
|> sort(columns: ["_value"], desc: false)
  |> difference()
  |> drop(columns: ["hash", "_measurement","is_private"]) 
  // convert Bytes to Gigabytes
  |> map(fn: (r) => ({r with _value: float(v: r._value) / 1073741824.0}))
  //|> map(fn: (r) => ({r with _value: math.round(x: r._value * 10.0) / 10.0}))
  |> sort(columns: ["_value"], desc: false)  
  |> drop(columns: ["_start", "_stop"]) 
  |> filter(fn: (r) => r._value != 0.0)  
  |> rename(columns: {_value: "uploaded [GB]",_time: "last timestamp"})
  |> drop(columns: ["_field"]) 
  |> sort(columns: ["uploaded [GB]"], desc: true)  
  |> group()
  |> sort(columns: ["uploaded [GB]"], desc: true)  
"""

return nothing 
end