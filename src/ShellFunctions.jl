module ShellFunctions

export echo, echo!, head, head!

using Glob

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
    i === nothing && return default
    options[i]
end

function echo(args...)
    options, pos_args = parse_args(args)
    _echo(options, pos_args)
end

function _echo(options, args)
    @show options
    @show args
    args
end

echo!(args...) = print(join(echo(args...), " "))

"""
    head(options..., files...)

Print the first 10 lines of each FILE to standard output.
With more than one FILE, precede each with a header giving the file name.

With no FILE, or when FILE is -, read standard input.

Mandatory arguments to long options are mandatory for short options too.

    :c and :bytes NOT implemented
    :c, :bytes => [-]NUM     print the first NUM bytes of each file;
                             with the leading '-', print all but the last
                             NUM bytes of each file
    :n, :lines=[-]NUM        print the first NUM lines instead of the first 10;
                             with the leading '-', print all but the last
                             NUM lines of each file
    :q, :quiet, :silent      never print headers giving file names
    :v, :verbose             always print headers giving file names

    :z and :zero_terminated NOT implemented
    :z, :zero-terminated    line delimiter is NUL, not newline
      :help     display this help and exit
      :version NOT implemented
      :version  output version information and exit

NUM may have a multiplier suffix:
b 512, kB 1000, K 1024, MB 1000\\*1000, M 1024\\*1024,
GB 1000\\*1000\\*1000, G 1024\\*1024\\*1024, and so on for T, P, E, Z, Y.

"""
function head(args...)
    options, pos_args = parse_args(args)
    _head(options, pos_args)
end

function _head(options, args)
    if get_option(options, :h, :help; default = nothing) !== nothing
        println(@doc head)
        return
    end

    multiple_files = length(args) > 1

    # TODO: Allow negative number of lines to read until n from the end.
    max_lines = get_option(
        options, :n, :lines; default = :lines => 10).second
    quiet = get_option(
        options, :q, :quiet, :silent; default = nothing) !== nothing
    verbose = get_option(
        options, :v, :verbose; default = nothing) !== nothing
    if verbose && quiet
        error(":verbose and :quiet both supplied. At most one can be.")
    end

    lines = []
    for fn in args
        file_lines = String[]
        n_lines = 0
        for fline = eachline(fn)
            push!(file_lines, fline)
            n_lines += 1
            n_lines == max_lines && break
        end
        if multiple_files
            if quiet
                push!(lines, file_lines)
            else
                push!(lines, fn => file_lines)
            end
        else
            if verbose
                push!(lines, fn => file_lines)
            else
                append!(lines, file_lines)
            end
        end
    end
    lines
end

function head!(args...)
    options, pos_args = parse_args(args)
    lines = _head(options, pos_args)
    lines === nothing && return

    multiple_files = length(pos_args) > 1
    if multiple_files
        for file_lines in lines
            _head_printlines(file_lines)
        end
    else
        if lines[1] isa Pair
            _head_printlines(lines[1])
        else
            _head_printlines(lines)
        end
    end
end

function _head_printlines(file_lines)
    for line in file_lines
        println(line)
    end
    println()
end


function _head_printlines(file_lines::Pair)
    println("==> ", file_lines.first, " <==")
    _head_printlines(file_lines.second)
end

end # module
