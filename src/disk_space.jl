#using PyCall

export disk_usage
function disk_usage(pt)
    @assert isdir(pt)

    @pyimport shutil

    v = shutil.disk_usage(pt)
return v 
end