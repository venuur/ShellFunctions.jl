# TODO: Fix filter to ignore directories.
# TODO: Add handling of errors to allow partial results.

export head, head!

@with_kw struct HeadOptions
    lines = 10
    quiet = false
    verbose = false
end

function parse_options(::Type{HeadOptions}, options)
    # TODO: Allow negative number of lines to read until n from the end.
    max_lines = get_option(
        options, :n, :lines; default = 10).second
    quiet = get_option(
        options, :q, :quiet, :silent, default = false).second
    verbose = get_option(
        options, :v, :verbose, default = false).second
    if verbose && quiet
        error(":verbose and :quiet both supplied. At most one can be.")
    end
    HeadOptions(
        lines = max_lines,
        quiet = quiet,
        verbose = verbose,
    )
end

"""
    head(options..., files...)

Return array of first 10 lines of each file.

With more than one file, return each as pair `file => lines` or print each
with a header giving the file name.
With no file, or when file is "-", read standard input.

Mandatory arguments to long options are mandatory for short options too.

    :n, :lines => [-]NUM    print the first NUM lines instead of the first 10;
                            with the leading '-', print all but the last
                            NUM lines of each file
    :q, :quiet, :silent     never print headers giving file names
    :v, :verbose            always print headers giving file names
      :help     display this help and exit

    FOLLOWING NOT IMPLEMENTED
    :c, :bytes => [-]NUM    print the first NUM bytes of each file;
                            with the leading '-', print all but the last
                            NUM bytes of each file
    :z, :zero-terminated    line delimiter is NUL, not newline
      :version  output version information and exit

NUM may have a multiplier suffix:
b 512, kB 1000, K 1024, MB 1000\\*1000, M 1024\\*1024,
GB 1000\\*1000\\*1000, G 1024\\*1024\\*1024, and so on for T, P, E, Z, Y.

"""
function head(args...)
    options_seq, pos_args = parse_args(args)
    do_print_usage(options_seq, @doc head) && return
    options = parse_options(HeadOptions, options_seq)
    _head(options, pos_args)
end

function _head(options, args)
    multiple_files = length(args) > 1
    max_lines = options.lines
    quiet = options.quiet
    verbose = options.verbose

    lines = []
    if length(args) == 0
        args = ["-"]
    end
    for fn in args
        file_lines = String[]
        n_lines = 0
        fn == "-" && fn == stdin
        for fline = eachline(fn)
            push!(file_lines, fline)
            n_lines += 1
            n_lines ≥ max_lines && break
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
    do_print_usage(options, @doc head) && return
    options = parse_options(HeadOptions, options)
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
