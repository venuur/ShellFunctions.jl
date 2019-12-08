export shcat, shcat!

@with_kw struct ShcatOptions
    show_ends = false
    number = false
end

function parse_options(::Type{ShcatOptions}, options)
    ShcatOptions(
        show_ends = get_option(options, :E, :show_ends, default = false).second,
        number = get_option(options, :n, :number, default = false).second,
    )
end

"""
    cat(options..., args...)

Concatenate FILE(s) to standard output.

With no FILE, or when FILE is -, read standard input.

    :A, :show_all           equivalent to :v, :E, :T
    :b, :number_nonblank    number nonempty output lines, overrides :n
    :e                      equivalent to :v, :E
    :E, :show_ends          display \$ at end of each line
    :n, :number             number all output lines
    :s, :squeeze_blank      suppress repeated empty output lines
    :t                      equivalent to :v, :T
    :T, :show_tabs          display TAB characters as ^I
    :u                      (ignored)
    :v, :show_nonprinting   use ^ and M- notation, except for LFD and TAB
      :help     display this help and exit
      :version  output version information and exit

Examples:
  cat f - g  Output f's contents, then standard input, then g's contents.
  cat        Copy standard input to standard output.

"""
function shcat(args...)
    options_seq, pos_args = parse_args(args)
    do_print_usage(options_seq, @doc shcat) && return
    options = parse_options(ShcatOptions, options)
    _shcat(options, pos_args)
end

function _shcat(options, args)
    number_all = options.number

    lines = []
    if length(args) == 0
        args = ["-"]
    end
    for fn in args
        fn == "-" && (fn = stdin)

        file_lines = readlines(fn)
        if number_all
            file_lines = [i => line for (i, line) in enumerate(file_lines)]
        end
        append!(lines, file_lines)
    end

    lines
end

function shcat!(args...)
    options_seq, pos_args = parse_args(args)
    do_print_usage(options_seq, @doc shcat) && return
    options = parse_options(ShcatOptions, options_seq)
    lines = _shcat(options, pos_args)
    nlines = length(lines)
    nspaces = (nlines |> log10 |> ceil |> Int) - 1
    n = 0
    ndigits = 1
    for line in lines
        if line isa Pair
            n += 1
            if n % 10 ^ ndigits == 0
                nspaces -= 1
                ndigits += 1
            end
            print(" "^nspaces, line.first, " ")
            line = line.second
        end
        print(line)
        options.show_ends && print("\$")
        println()
    end
end
