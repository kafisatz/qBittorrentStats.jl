#using PyCall

export freediskspace
function freediskspace(pt)

    @assert isdir(pt)
    v=py"get_fs_freespace"(pt)

    #v2=py"pydiskspace"(pt)

    #v[1]/1024/1024/1024
    return v./(2^30)
end
