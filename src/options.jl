using Glob: glob

function parse_args(args)
    isoption(a) = a isa Symbol || a isa Pair
    options = [a for a in args if isoption(a)]
    pos_args = String[]
    for (a, g) in ((a, glob(string(a))) for a in args if !isoption(a))
        if length(g) == 0
            push!(pos_args, string(a))
        else
            append!(pos_args, g)
        end
    end
    return options, pos_args
end

optionequal(option::Symbol, name) = return option === name
optionequal(option::Pair, name) = return option.first === name
anyoptionequal(option, names...) = any(optionequal(option, n) for n in names)

function get_option(options, names...; default = nothing)
    i = findnext(o -> anyoptionequal(o, names...), options, 1)
    if i === nothing
        if !(default isa Pair)
            default = names[1] => default
        end
        return default
    end
    found = options[i]
    if !(found isa Pair)
        return found => true
    else
        return found
    end
end
