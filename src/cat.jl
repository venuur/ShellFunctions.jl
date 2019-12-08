export shcat, shcat!

@with_kw struct ShcatOptions
    show_ends = false
    number = false
    number_nonblank = false
end

function parse_options(::Type{ShcatOptions}, options)
    ShcatOptions(
        show_ends = get_option(options, :E, :show_ends, default = false).second,
        number = get_option(options, :n, :number, default = false).second,
        number_nonblank = get_option(
            options,
            :b,
            :number_nonblank,
            default = false,
        ).second,
    )
end

"""
    shcat(options..., files...)

Return lines of files concatenated into a single array.

With no files, or when file is "-", read standard input.

    :b, :number_nonblank    number nonempty output lines as `n => line`,
                            overrides :n
    :E, :show_ends          display \$ at end of each line
    :n, :number             number all output lines as `n => line`
      :help     display this help and exit

    FOLLOWING NOT IMPLEMENTED
    :A, :show_all           equivalent to :v, :E, :T
    :e                      equivalent to :v, :E
    :s, :squeeze_blank      suppress repeated empty output lines
    :t                      equivalent to :v, :T
    :T, :show_tabs          display TAB characters as ^I
    :u                      (ignored)
    :v, :show_nonprinting   use ^ and M- notation, except for LFD and TAB
      :version  output version information and exit

# Examples

    shcat("f", "-", "g") # Output f's contents, then standard input, then g's
                         # contents.
    shcat!()        # Copy standard input to standard output.

"""
function shcat(args...)
    options_seq, pos_args = parse_args(args)
    do_print_usage(options_seq, @doc shcat) && return
    options = parse_options(ShcatOptions, options_seq)
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
        if options.number_nonblank
            n = 1
            numbered_lines = Array{Any}(undef, length(file_lines))
            for i in eachindex(file_lines)
                if length(file_lines[i]) > 0
                    numbered_lines[i] = n => file_lines[i]
                    n += 1
                else
                    numbered_lines[i] = ""
                end
            end
            file_lines = numbered_lines
        elseif number_all
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
            if n % 10^ndigits == 0
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
