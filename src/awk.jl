export awk

@with_kw struct AwkOptions
    field_separator = " "
    source = nothing
end

function parse_options(::Type{AwkOptions}, options)
    AwkOptions(
        source = get_option(options, :e, :source).second,
    )
end

"""
    awk(options..., prog, files...)

Usage: awk [POSIX or GNU style options] -f progfile [--] file ...
Usage: awk [POSIX or GNU style options] [--] 'program' file ...
POSIX options:          GNU long options: (standard)
        -f progfile             --file=progfile
        -F fs                   --field-separator=fs
        -v var=val              --assign=var=val
Short options:          GNU long options: (extensions)
        -b                      --characters-as-bytes
        -c                      --traditional
        -C                      --copyright
        -d[file]                --dump-variables[=file]
        -D[file]                --debug[=file]
        -e 'program-text'       --source='program-text'
        -E file                 --exec=file
        -g                      --gen-pot
        -h                      --help
        -i includefile          --include=includefile
        -l library              --load=library
        -L[fatal|invalid]       --lint[=fatal|invalid]
        -M                      --bignum
        -N                      --use-lc-numeric
        -n                      --non-decimal-data
        -o[file]                --pretty-print[=file]
        -O                      --optimize
        -p[file]                --profile[=file]
        -P                      --posix
        -r                      --re-interval
        -S                      --sandbox
        -t                      --lint-old
        -V                      --version

To report bugs, see node 'Bugs' in 'gawk.info', which is
section 'Reporting Problems and Bugs' in the printed version.

gawk is a pattern scanning and processing language.
By default it reads standard input and writes standard output.

# Examples

    gawk '{ sum += \$1 }; END { print sum }' file
    gawk -F: '{ print \$1 }' /etc/passwd

"""
function awk(args...)
    options_seq, pos_args = parse_args(args)
    do_print_usage(options_seq, @doc awk) && return
    options = parse_options(AwkOptions, options_seq)
    _awk(options, pos_args)
end

function _awk(options, args)
    # TODO: Select program based on file or source options as well as first
    #       positional argument.
    program = options.source
    program === nothing && return
    # Each element of program is either a function or a pair.
    # Functions are run every time on each line.
    # Pairs are a predicate plus action. The first term is a predicate, so that
    # the action only runs if the predicate returns true. The action is the same
    # as a stand alone function.
    # The function has signature f(vars, fields) and can return any value.
    # Return nothing to not append anything to result.

    function read_fields(fn)
        if options.field_separator == " "
            return readdlm(fn, String, quotes=false)
        else
            return readdlm(fn, '=', String, quotes=false)
        end
    end

    ret = []
    vars = []
    for fn in args
        fields = read_fields(fn)
        # Swap dims so we index by column major order.
        fields = permutedims(fields)
        for i in axes(fields, 2)
            for rule in program
                if rule isa Pair
                    if rule.first(vars, fields[:, i])
                        result = rule.second(vars, fields[:, i])
                    else
                        result = nothing
                    end
                else
                    result = rule(vars, fields[:, i])
                end
                result !== nothing && push!(ret, result)
            end
        end
    end
    ret
end
