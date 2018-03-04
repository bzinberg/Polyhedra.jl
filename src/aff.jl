export HAffineSpace, VAffineSpace, affinehull, linespace, detecthlinearities!, detectvlinearities!

# Linearity
detectvlinearities!(p::VRep) = error("detectvlinearities! not implemented for $(typeof(p))")
detecthlinearities!(p::HRep) = error("detecthlinearities! not implemented for $(typeof(p))")
function dim(h::HRep{N}, current=false) where N
    if !current
        detecthlinearities!(h::HRep)
    end
    N - nhyperplanes(h)
end


# It is easy to go from H-rep of affine space to V-rep of affine space by computing the kernel of a matrix using RowEchelon
# However, it is really worth it since Base.in for an HRepElement in HAffineSpace and Base.in for an VRepElement in VAffineSpace are false already.
function remproj(x::RepElement{N, <:Integer}, l::RepElement{N, <:Integer}) where N
    # generates large numbers but keeps the type integer
    x * dot(coord(l), coord(l)) - l * dot(coord(x), coord(l))
end
function remproj(x, l)
    simplify(x - l * (dot(coord(x), coord(l)) / dot(coord(l), coord(l))))
end

# H-representation

"""
    hrep(hyperplanes::HyperPlaneIt)

Creates an affine space from the list of hyperplanes `hyperplanes`.

### Examples
```julia
hrep([HyperPlane([0, 1, 0], 1), HyperPlane([0, 0, 1], 0)])
```
creates the 1-dimensional affine subspace containing all the points ``(x_1, 0, 0)``, i.e. the ``x_1``-axis.

```julia
hrep([HyperPlane([1, 1], 1), HyperPlane([1, 0], 0)])
```
creates the 0-dimensional affine subspace only containing the point ``(0, 1)``.
"""
hrep(hyperplanes::HyperPlaneIt) = HAffineSpace(hyperplanes)

abstract type HAffineRep{N, T} <: HRepresentation{N, T} end

@norepelem HAffineRep HalfSpace

# Representation of an affine space as the intersection of hyperplanes.
# Also called affine set, affine manifold, affine variety, linear variety or flat.
# An affine space L satisfies:
# λx + (1-λ)y ∈ L, ∀x, y ∈ L, ∀ λ ∈ R
# Note that λ is not rhyperplaneuired to be between 0 and 1 as in convex sets.
struct HAffineSpace{N, T, AT} <: HAffineRep{N, T}
    # HyperPlanes whose intersection is the affine space
    hps::Vector{HyperPlane{N, T, AT}}
    function HAffineSpace{N, T, AT}(hps::Vector{HyperPlane{N, T, AT}}) where {N, T, AT}
        new{N, T, AT}(hps)
    end
end
arraytype(L::HAffineSpace{N, T, AT}) where {N, T, AT} = AT

HAffineSpace{N, T, AT}() where {N, T, AT} = HAffineSpace{N, T, AT}(HyperPlane{N, T, AT}[])
function HAffineSpace{N, T, AT}(it::ElemIt{HyperPlane{N, T, AT}}) where {N, T, AT}
    HAffineSpace{N, T, AT}(collect(it))
end
HAffineSpace(it::ElemIt{HyperPlane{N, T, AT}}) where {N, T, AT} = HAffineSpace{N, T, AT}(it)

Base.intersect!(L::HAffineSpace{N}, h::HyperPlane{N}) where N = push!(L.hps, h)

@vecrepelem HAffineSpace HyperPlane hps
#Base.length(idxs::Indices{N, T, HyperPlane{N, T}, <:HAffineRep{N, T}}) where {N, T, ElemT} = length(idxs.rep.hps)
#Base.isempty(idxs::Indices{N, T, HyperPlane{N, T}, <:HAffineRep{N, T}}) where {N, T, ElemT} = isempty(idxs.rep.hps)
#Base.start(idxs::Indices{N, T, HyperPlane{N, T}, <:HAffineRep{N, T}}) where {N, T, ElemT} = HyperPlaneIndex{N, T}(1)
#Base.done(idxs::Indices{N, T, HyperPlane{N, T}, <:HAffineRep{N, T}}, idx::HyperPlaneIndex{N, T}) where {N, T} = idx.value > length(idxs)
#Base.get(L::HAffineSpace{N, T}, idx::HyperPlaneIndex{N, T}) where {N, T} = L.hps[idx.value]
#nextindex(L::HAffineSpace{N, T}, idx::HyperPlaneIndex{N, T}) where {N, T} = HyperPlaneIndex{N, T}(idx.value+1)

# Returns an HAffineSpace representing the affine hull of p.
# The affine hull is defined as
# {λx + (1-λ)y | x, y ∈ p, λ ∈ R}
function affinehull(h::HRep, current=false)
    if !current
        detecthlinearities!(h)
    end
    HAffineSpace(hyperplanes(h))
end

function remproj(h::HRepElement, L::HAffineSpace)
    for hp in hyperplanes(L)
        h = remproj(h, hp)
    end
    h
end
function Base.in(h::HRepElement, L::HAffineSpace)
    h = remproj(h, L)
    myeqzero(h)
end

function removeduplicates(L::HAffineSpace{N, T, AT}) where {N, T, AT}
    H = HAffineSpace{N, T, AT}()
    for h in hyperplanes(L)
        if !(h in H)
            intersect!(H, h)
        end
    end
    H
end

# V-representation

"""
    vrep(lines::LineIt)

Creates an affine space from the list of lines `lines`.

### Examples
```julia
vrep([Line([1, 0, 0]), Line([0, 1, 0])])
```
creates the 2-dimensional affine subspace containing all the points ``(x_1, x_2, 0)``, i.e. the ``x_1````x_2``-plane.
"""
vrep(lines::LineIt) = VAffineSpace(lines)

# See issue #28
Base.length(idxs::PointIndices{N, T, <:VCone{N, T}}) where {N, T} = hasallrays(idxs.rep) ? 1 : 0
Base.isempty(idxs::PointIndices{N, T, <:VCone{N, T}}) where {N, T} = !hasallrays(idxs.rep)
Base.start(idxs::PointIndices{N, T, <:VCone{N, T}}) where {N, T} = eltype(idxs)(hasallrays(idxs.rep) ? 1 : 2)
Base.done(idxs::PointIndices{N, T, <:VCone{N, T}}, idx::PointIndex{N, T}) where {N, T} = idx.value > 1
Base.get(L::VCone{N, T, AT}, idx::PointIndex{N, T}) where {N, T, AT} = _zeros(AT, FullDim{N}())
nextindex(L::VCone{N, T}, idx::PointIndex{N, T}) where {N, T} = typeof(idx)(idx.value + 1)

# Representation of an affine space containing the origin by the minkowsky sum of lines
struct VAffineSpace{N, T, AT} <: VCone{N, T, AT}
    lines::Vector{Line{N, T, AT}}
    function VAffineSpace{N, T, AT}(lines::Vector{Line{N, T, AT}}) where {N, T, AT}
        new{N, T, AT}(lines)
    end
end
arraytype(L::VAffineSpace{N, T, AT}) where {N, T, AT} = AT

VAffineSpace{N, T, AT}() where {N, T, AT} = VAffineSpace{N, T, AT}(Line{N, T, AT}[])
function VAffineSpace{N, T, AT}(it::ElemIt{Line{N, T, AT}}) where {N, T, AT}
    VAffineSpace{N, T, AT}(collect(it))
end
VAffineSpace(it::ElemIt{Line{N, T, AT}}) where {N, T, AT} = VAffineSpace{N, T, AT}(it)

convexhull!(L::VAffineSpace{N}, l::Line{N}) where {N} = push!(L.lines, l)

@norepelem VAffineSpace Ray
@vecrepelem VAffineSpace Line lines

# Returns a VAffineSpace representing the following set (TODO does it have a name?, does someone has a reference talking about it ?)
# {x | ⟨a, x⟩ = 0 ∀ a such that (α, β) is a valid inhyperplaneuality for p}
function linespace(v::VRep, current=false)
    if !current
        detectvlinearities!(v)
    end
    VAffineSpace(lines(v))
end

function remproj(v::VRepElement, L::VAffineSpace)
    for l in lines(L)
        v = remproj(v, l)
    end
    v
end
function Base.in(v::VRepElement, L::VAffineSpace)
    v = remproj(v, L)
    myeqzero(coord(v))
end

function removeduplicates(L::VAffineSpace{N, T, AT}) where {N, T, AT}
    V = VAffineSpace{N, T, AT}()
    for h in hyperplanes(L)
        if !(h in H)
            convexhull!(H, h)
        end
    end
    H
end
