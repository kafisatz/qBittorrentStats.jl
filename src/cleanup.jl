export delete_torrents_if_data_threshold_is_exceeded
function delete_torrents_if_data_threshold_is_exceeded(baseurl_info,baseurl,cookieDict,lastactivitydf;deletefiles=true,threshold_in_tb=20.0,password=nothing)
    #=
        threshold_in_tb = 19.9
    =#
    if threshold_in_tb <= 0
        return 0 
    end

    have_tb = sum(select(unique(lastactivitydf,:hash),Not(:sizegb_cumsum)).sizegb)/1024
    #sum(lastactivitydf.sizegb) #overstates true space usage
    if have_tb < threshold_in_tb
        return 0
    end

    lastactivitydf_mod = deepcopy(lastactivitydf)
    select!(lastactivitydf_mod,Not(:sizegb_cumsum))
    unique!(lastactivitydf_mod,:hash)
    #note: name is not unique! two torrents can have the same name but be entirely different torrents!
    #filter(x->x.name_length>1,combine(groupby(lastactivitydf,:name),:name=>length))
    lastactivitydf_mod.sizegb_cumsum = cumsum(lastactivitydf_mod.sizegb)

    idx = lastactivitydf_mod.sizegb_cumsum .> threshold_in_tb*1024
    hashes_to_delete = lastactivitydf_mod.hash[idx]

    @show hashes_to_delete

    lastactivitydf_del = filter(x->in(x.hash,hashes_to_delete),lastactivitydf)

    names_to_delete = lastactivitydf_del.name
    @show names_to_delete
    
    #identify "youngest" torrent
    mi,ma = extrema(lastactivitydf_del.added_on_dt)
    age_in_days = round(round(now()-ma,Hour).value/24,digits=2)
    if length(names_to_delete) >0 
        @info("$baseurl_info - Youngest torrent to be deleted has been added $age_in_days days ago")
    end
    
    ndeleted = 0
    for h in hashes_to_delete
        #@info("Deleting torrent with hash $h")
        rs = deletetorrent(h,baseurl,cookieDict=cookieDict,password=password)
        ndeleted +=1
    end

    return ndeleted
end
