export cleanup
function cleanup(baseurl,cookieDict,lastactivitydf;deletefiles=true,threshold_in_tb::Int=20::Int)
    #threshold_in_tb = 20
    if threshold_in_tb <= 0 
        return nothing 
    end

    have_tb = maximum(lastactivitydf.sizegb_cumsum)/1024
    if have_tb < threshold_in_tb
        return nothing 
    end

    hashes_to_delete = lastactivitydf.hash[lastactivitydf.sizegb_cumsum .> threshold_in_tb*1024]
    reverse!(hashes_to_delete)
    
    ndeleted = 0
    for h in hashes_to_delete
        #@info("Deleting torrent with hash $h")
        rs = deletetorrent(h,baseurl,cookieDict=cookieDict)
        ndeleted +=1
    end

    return ndeleted
end