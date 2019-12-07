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
