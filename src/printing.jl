# Pretty-printing for AbstractHeterogeneousVector.
#
# See https://github.com/yaccos/HeterogeneousArrays.jl/issues/31 for the
# discussion leading to this layout: each field is shown on its own line
# using its natural `show` representation, except that array fields whose
# elements share a single Unitful unit are printed as a plain numeric array
# followed by that unit once, instead of the verbose parametric `Quantity`
# element type Julia would otherwise print for every element.

function Base.summary(io::IO, hv::AbstractHeterogeneousVector{T}) where {T}
    print(io, length(hv), "-element ", nameof(typeof(hv)), "{", T,
        "} with fields ", propertynames(hv))
end

function Base.show(io::IO, ::MIME"text/plain", hv::AbstractHeterogeneousVector)
    summary(io, hv)
    names = propertynames(hv)
    isempty(names) && return
    print(io, ":")
    ctx = IOContext(io, :compact => true, :limit => true)
    nt = NamedTuple(hv)
    for name in names
        println(ctx)
        print(ctx, "  ", name, " = ")
        _show_field(ctx, getfield(nt, name))
    end
end

_show_field(io, x::Ref) = show(io, x[])
_show_field(io, x) = show(io, x)

function _show_field(io, x::AbstractArray)
    E = eltype(x)
    if isconcretetype(E) && E <: Unitful.AbstractQuantity
        u = Unitful.unit(E)
        show(io, Unitful.ustrip.(u, x))
        u === Unitful.NoUnits || print(io, " ", u)
    else
        show(io, x)
    end
end
