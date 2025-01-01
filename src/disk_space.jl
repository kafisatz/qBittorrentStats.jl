#using PyCall

export diskspace
function diskspace(pt)

    @assert isdir(pt)
    v=py"pydiskspace"(pt)

    #v[1]/1024/1024/1024
    return v./(2^30)
end
