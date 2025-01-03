
export read_files
function read_files(dir)
    #dir=raw"\\ds\data_ssd\downloads_torrent_clients\dockervm"
    rs = readdir(dir,join=true)
    rs2 = readdir(dir)
    return rs,rs2
end


export delete_torrents_without_data
function delete_torrents_without_data(dir,lastactivitydf)
    rs,rs2 = read_files(dir)

    df = unique(lastactivitydf,:name)

    data_but_no_torrent = setdiff(rs2,df.name)
    torrent_without_data = setdiff(df.name,rs2)

    df_torrent_without_data = filter(x->x.name in torrent_without_data,lastactivitydf)

    StatsBase.countmap(map(x->x[1:15],df_torrent_without_data.tracker))
    
    hashes_to_delete = df_torrent_without_data.hash

    ndeleted = 0
    for h in hashes_to_delete
        #@info("Deleting torrent with hash $h")
        rs = deletetorrent(h,baseurl,cookieDict=cookieDict)
        ndeleted +=1
    end

    return nothing 
end