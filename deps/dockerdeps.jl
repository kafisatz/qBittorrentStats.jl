@info("Currently there are no dependencies for this package.")

ENV["PYTHON"] = ""
using Pkg 
Pkg.build("PyCall")