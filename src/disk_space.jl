#using PyCall

export freediskspace
function freediskspace(pt)

    @assert isdir(pt)
    v = py"get_fs_freespace"(pt)

    #v2=py"pydiskspace"(pt)

    #v[1]/1024/1024/1024
    return v./(2^30)
end

#=
freediskspace(raw"\\ds\data\media")

freediskspace("/tmp")

free_space_in_gb = freediskspace("/volume2/data_ssd")
free_space_in_tb = free_space_in_gb/1024
=#