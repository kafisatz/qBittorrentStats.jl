export delete_torrents_if_data_threshold_is_exceeded
function delete_torrents_if_data_threshold_is_exceeded(baseurl,cookieDict,lastactivitydf;deletefiles=true,threshold_in_tb=20.0)
    #=
        threshold_in_tb = 19.9
    =#
    if threshold_in_tb <= 0
        return 0 
    end

    have_tb = sum(select(unique(lastactivitydf,:name),Not(:sizegb_cumsum)).sizegb)/1024
    #sum(lastactivitydf.sizegb) #overstates true space usage
    if have_tb < threshold_in_tb
        return 0
    end

    lastactivitydf_mod = deepcopy(lastactivitydf)
    select!(lastactivitydf_mod,Not(:sizegb_cumsum))
    unique!(lastactivitydf_mod,:name)
    lastactivitydf_mod.sizegb_cumsum = cumsum(lastactivitydf_mod.sizegb)

    idx = lastactivitydf_mod.sizegb_cumsum .> threshold_in_tb*1024
    names_to_delete = lastactivitydf_mod.name[idx]
    @show names_to_delete

    lastactivitydf_del = filter(x->in(x.name,names_to_delete),lastactivitydf)
    #unique(lastactivitydf_del,:name)
    hashes_to_delete = lastactivitydf_del.hash
    
    ndeleted = 0
    for h in hashes_to_delete
        #@info("Deleting torrent with hash $h")
        rs = deletetorrent(h,baseurl,cookieDict=cookieDict)
        ndeleted +=1
    end

    return ndeleted
end
