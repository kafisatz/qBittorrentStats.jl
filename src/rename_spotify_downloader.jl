dr = raw"C:\Users\BernhardKönig\Downloads\kasperli"
@assert isdir(dr)

fis = readdir(dr, join=true)
f=fis[1]
for f in fis
    fldr,fn = splitdir(f)
    rpl = "[SPOTIFY-DOWNLOADER.COM] "
    if occursin(rpl,fn)
        newname = joinpath(fldr,replace(fn,rpl=>""))
        mv(f,newname)
    end
end