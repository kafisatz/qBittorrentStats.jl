
export read_files
function read_files(dir)
    #dir=raw"\\ds\data_ssd\downloads_torrent_clients\dockervm"
    rs = readdir(dir,join=true)
    rs2 = readdir(dir)
    return rs,rs2
end

export delete_torrents_without_data_and_data_without_torrents
function delete_torrents_without_data_and_data_without_torrents(dir,lastactivitydf,cookieDict;ntorrents_to_delete_threshold=10,data_to_delete_without_torrent_threshold_tib=1.0)
    #ntorrents_to_delete_threshold=10;data_to_delete_without_torrent_threshold_tib=1.0
    rs,rs2 = read_files(dir)

    df = unique(lastactivitydf,:name)
    
    torrent_without_data = setdiff(df.name,rs2)

    ####################################################################################################
    data_but_no_torrent = setdiff(rs2,df.name)

    #filter data_but_no_torrent
        #very new torrents may not yet have data on disk!
        #data_but_no_torrent=lastactivitydf.name[1:200]
        #sort!(lastactivitydf,:added_on,rev=true)
        data_but_no_torrent_df = filter(x->x.name in data_but_no_torrent,lastactivitydf)
        min_age_of_torrent = Hour(4) #note UTC vs CET can make up 1 hour (or mabe even 2? )
        #data_but_no_torrent_df.added_on_dt
        
        filter!(x-> x.added_on_dt < now() - min_age_of_torrent,data_but_no_torrent_df)
        data_but_no_torrent = data_but_no_torrent_df.name
    ####################################################################################################

    data_but_no_torrent_with_path = joinpath.(dir,data_but_no_torrent)
    @assert all(x->isdir(x) || isfile(x),data_but_no_torrent_with_path)

    data_but_no_torrent_size_tib = get_size(data_but_no_torrent_with_path)

    ################################################################################
    #delete data which has no torrent
    ################################################################################
    if (data_but_no_torrent_size_tib > 0.0) || (length(data_but_no_torrent_with_path) > 0)
        if data_but_no_torrent_size_tib > data_to_delete_without_torrent_threshold_tib
            @warn("Not deleting any data. Analysis indicates that $(data_but_no_torrent_size_tib) TiB of data has no corresponding torrents. Please review manually")
        else
            #delete data 
            @info "Deleting data without torrents: $(data_but_no_torrent_size_tib) TiB" data_but_no_torrent
            rs = delete_data_wo_torrent(data_but_no_torrent_with_path)
        end
    end

    ################################################################################
    #delete torrents without underlying data
    ################################################################################

    df_torrent_without_data = filter(x->x.name in torrent_without_data,lastactivitydf)

    if size(df_torrent_without_data,1) > 0
        #StatsBase.countmap(map(x->x[1:min(length(x),15)],df_torrent_without_data.tracker))        
        hashes_to_delete = df_torrent_without_data.hash

        if size(hashes_to_delete,1) > ntorrents_to_delete_threshold
            nt = length(hashes_to_delete)
            @warn("Not deleting any torrents. Analysis indicates that $(nt) torrents have no underlying data. Please review manually")
        else 
            ndeleted = 0
            for h in hashes_to_delete
                @info("Deleting torrent without data on disk $h")
                rs = deletetorrent(h,baseurl,cookieDict=cookieDict)
                ndeleted +=1
            end    
        end
    end
    
    return nothing 
end

export get_size
function get_size(data_but_no_torrent_with_path)

    total_size_bytes = 0
    for path in data_but_no_torrent_with_path
        if isfile(path)
            total_size_bytes += filesize(path)
        elseif isdir(path)
            for (root, dirs, files) in walkdir(path)
                for file in files
                    total_size_bytes += filesize(joinpath(root, file))
                end
            end
        end
    end

    total_size_tib = total_size_bytes / 1024 / 1024 / 1024 / 1024
    return total_size_tib
    return nothing  
end 

export delete_data_wo_torrent
function delete_data_wo_torrent(data_but_no_torrent_with_path)
    for fi_or_fldr in data_but_no_torrent_with_path
        if isdir(fi_or_fldr)
            rm(fi_or_fldr, recursive=true)
        else 
            rm(fi_or_fldr)
        end
    end
    return nothing 
end