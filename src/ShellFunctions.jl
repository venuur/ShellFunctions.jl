module ShellFunctions

using Parameters: @with_kw

include("options.jl") # provides Options module
using .Options

include("echo.jl")
include("head.jl")
include("cat.jl")

using DelimitedFiles
include("awk.jl")

end # module
