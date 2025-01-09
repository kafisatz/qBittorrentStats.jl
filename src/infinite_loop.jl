using Pkg; 
Pkg.activate("."); Pkg.instantiate()

#using Revise
using Dates; using DataFrames; using StatsBase; using qBittorrentStats;import InfluxDBClient

baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl,data_dirs = init_global_vars()

THRESHOLD_IN_TIB = 35.0 #we are currently using the SSD volume (space is limited!)
nsecsleep = 10*60
while true
    try
        #this may error if the retention policy is finite, need to find out why though....
        cookieDict,lastactivitydf = writestats(baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl=uptimekumaurl)
        tb_mean_over_last_x_days,ntorrents_mean_over_last_x_days,x = daily_volume(lastactivitydf)
        @show tb_mean_over_last_x_days,ntorrents_mean_over_last_x_days,x
        ntorrents = size(lastactivitydf,1)
        
        #cross seeds only need space 'once' per torrent name!
        space_usage_tib = round(sum(select(unique(lastactivitydf,:name),Not(:sizegb_cumsum)).sizegb)/1024, digits = 2)
        #sum(lastactivitydf.sizegb)/1024 #overstates true space usage
        
        ndeleted = delete_torrents_if_data_threshold_is_exceeded(baseurl,cookieDict,lastactivitydf,threshold_in_tb=THRESHOLD_IN_TIB)
        space_left_tib_until_torrent_pruning_starts = round(THRESHOLD_IN_TIB .- space_usage_tib,digits=2)

        #################################################################################
        #clean up data (torrents without data are deleted & folders/files without torrent are also deleted)
        
        if size(data_dirs,1) > 0 
            dir = data_dirs[1]
            if isdir(dir)
                delete_torrents_without_data_and_data_without_torrents(dir,lastactivitydf,cookieDict)
            end
        end
        #################################################################################

        ts2 = timestring()
        ts3 = "Europe/Zurich now = $(ts2)"

        msg = "THRESHOLD_IN_TIB = $(THRESHOLD_IN_TIB) TiB - space_usage_tib = $(space_usage_tib) TiB - space_left_tib_until_torrent_pruning_starts = $(space_left_tib_until_torrent_pruning_starts) TiB - Number of torrents: $(ntorrents) - " * ts3
        if iszero(ndeleted)
            @info("Nothing was deleted. " * msg)
        else
            s = ndeleted > 1 ? "s" : ""
            @info("$(ndeleted) torrent$(s) deleted.       " * msg)
        end
    catch er
        @show er
    end
    sleep(nsecsleep)
end

#=
    dir=raw"\\ds\data_ssd\downloads_torrent_clients\dockervm"
    @time cookieDict,lastactivitydf = writestats(baseurl,influxdbbucketname,influxdbsettings,uptimekumaurl=uptimekumaurl)
    delete_torrents_without_data_and_data_without_torrents(dir,lastactivitydf)
=#