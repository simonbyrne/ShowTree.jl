module ShowTree

export show_tree

show_tree(x) = show_tree(STDOUT, x)

function show_tree(io::IO, x, indent_root="", indent_leaf="")
    print(io, indent_root)
    if iscompact(x)
        _show_compact(io, x)
        println(io)
    else
        _show_root(io, x)
        print(io, '\n')
        cs = _children(x)
        for (i,c) in enumerate(cs)
            if i < length(cs)
                show_tree(io, c, indent_leaf*rootsyms(x)[1], indent_leaf*leafsyms(x)[1])
            else
                show_tree(io, c, indent_leaf*rootsyms(x)[2], indent_leaf*leafsyms(x)[2])
            end
        end
    end
end

rootsyms(x) = ("├─","└─")
leafsyms(x) = ("│ ","  ")

isvarargs(x::DataType) = x <: Tuple && x.parameters[end] <: Vararg{Any}
_show_root(io::IO, x::DataType) = print(io, x.name)
function _children(x::DataType)
    params = isvarargs(x) ? [x.parameters[1:end-1]...,x.parameters[end].body.parameters[1]] : x.parameters
    map(strip_typebounds, params)
end

struct ParamTypeVar
name::Symbol
end

_show_root(io::IO, x::ParamTypeVar) = print_with_color(:light_magenta, io, x.name)

strip_typebounds(x) = x
strip_typebounds(x::TypeVar) = TypeVar(x.name)



iscompact(x::Union) = false
iscompact(x::DataType) = !isvarargs(x) && all(iscompact ∘ strip_typebounds, x.parameters)
iscompact(x::TypeVar) = x.lb === Base.Bottom && x.ub === Any
iscompact(x::UnionAll) = iscompact(x.var) && iscompact(x.body)
iscompact(x::ParamTypeVar) = true
iscompact(x) = true

_show_compact(io, x) = show(io,x)
function _show_compact(io, x::DataType)
    show(io, x.name)
    if length(x.parameters) > 0
        print(io, "{")
        _show_compact(io, x.parameters[1])
        for i = 2:length(x.parameters)
            print(io,",")
            _show_compact(io, x.parameters[i])
        end
        print(io, "}")
    end
end

unionall_body(x) = x
unionall_body(x::UnionAll) = unionall_body(x.body)

unionall_vars(x) = []
unionall_vars(x::UnionAll) = [x.var, unionall_vars(x.body)...]

function _show_compact(io, x::UnionAll)
    print_with_color(:cyan, io, "UnionAll ")
    _show_compact(io, unionall_body(x))
    print(io," ")
    print_with_color(:cyan, io, "where")
    print(io," {")
    params = unionall_vars(x)
    _show_compact(io, params[1])
    for i = 2:length(params)
        print(io,",")
        _show_compact(io, params[i])
    end
    print(io, "}")
end

rootsyms(x::DataType) = isvarargs(x) ? ("├─","⧆─") : ("├─","└─")
leafsyms(x::DataType) = isvarargs(x) ? ("│ ","┊ ") : ("│ ","  ")

_show_root(io::IO, x) = print(io, x)
_children(x) = []

_show_root(io::IO, x::Union) = print_with_color(:cyan, io, "Union")
_children(x::Union) = x.b isa Union ? [x.a, _children(x.b)...] : [x.a, x.b]

_show_root(io::IO, x::UnionAll) = print_with_color(:cyan, io, "UnionAll")
_children(x::UnionAll) = x.body isa UnionAll ? [_children(x.body)..., x.var] : [x.body, x.var]

_show_root(io::IO, x::TypeVar) = print_with_color(:magenta, io, x.name)
_children(x::TypeVar) = x.lb !== Base.Bottom ? [x.lb, x.ub] : x.ub !== Any ? [x.ub] : []
_show_compact(io, x::TypeVar) = print_with_color(:magenta, io, x.name)

leafsyms(x::TypeVar) = ("│  ","   ")
rootsyms(x::TypeVar) = ("├>:","└<:")


# show_tree(StridedVecOrMat)



struct IndentedIO{T} <: IO
    io::T
    indent::String
end

function Base.write(ind::IndentedIO, c::Char)
    j = write(ind.io, c)
    if c == '\n'
        j += write(ind.io, ind.indent)
    end
    j
end

function Base.write(ind::IndentedIO, s::String)
    j = 0
    for l = readlines(IOBuffer(s), chomp=false)
        j += write(ind.io, l)
        if endswith(l, '\n')
            j += write(ind.io, ind.indent)
        end
    end
    j
end


end # module
