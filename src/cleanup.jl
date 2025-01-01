export cleanup
function cleanup(baseurl,cookieDict,lastactivitydf;deletefiles=true,free_threshold_in_tb=20.0)
    #=
        free_threshold_in_tb = 19.9
    =#
    if free_threshold_in_tb <= 0
        return 0 
    end

    have_tb = maximum(lastactivitydf.sizegb_cumsum)/1024
    if have_tb < free_threshold_in_tb
        return 0
    end

    idx = lastactivitydf.sizegb_cumsum .> free_threshold_in_tb*1024
    hashes_to_delete = lastactivitydf.hash[idx]
    reverse!(hashes_to_delete)
    names_to_delete = lastactivitydf.name[idx]
    
    ndeleted = 0
    for h in hashes_to_delete
        #@info("Deleting torrent with hash $h")
        rs = deletetorrent(h,baseurl,cookieDict=cookieDict)
        ndeleted +=1
    end

    return ndeleted
end