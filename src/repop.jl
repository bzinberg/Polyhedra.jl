export convexhull

"""
    intersect(P1::HRep, P2::HRep)

Takes the intersection of `P1` and `P2` ``\\{\\, x : x \\in P_1, x \\in P_2 \\,\\}``.
It is very efficient between two H-representations or between two polyhedron for which the H-representation has already been computed.
However, if `P1` (resp. `P2`) is a polyhedron for which the H-representation has not been computed yet, it will trigger a representation conversion which is costly.
See the [Polyhedral Computation FAQ](http://www.cs.mcgill.ca/~fukuda/soft/polyfaq/node25.html) for a discussion on this operation.

The type of the result will be chosen closer to the type of `P1`. For instance, if `P1` is a polyhedron (resp. H-representation) and `P2` is a H-representation (resp. polyhedron), `intersect(P1, P2)` will be a polyhedron (resp. H-representation).
If `P1` and `P2` are both polyhedra (resp. H-representation), the resulting polyhedron type (resp. H-representation type) will be computed according to the type of `P1`.
The coefficient type however, will be promoted as required taking both the coefficient type of `P1` and `P2` into account.
"""
function Base.intersect(p1::RepTin, p2::HRep{N, T2}) where {N, T1, T2, RepTin<:HRep{N, T1}}
    Tout = promote_type(T1, T2)
    # Always type of first arg
    RepTout = lazychangeeltype(RepTin, Tout)
    RepTout(HRepIterator([HRep{N, Tout}(p1), HRep{N, Tout}(p2)]))
end

"""
    convexhull(P1::VRep, P2::VRep)

Takes the convex hull of `P1` and `P2` ``\\{\\, \\lambda x + (1-\\lambda) y : x \\in P_1, y \\in P_2 \\,\\}``.
It is very efficient between two V-representations or between two polyhedron for which the V-representation has already been computed.
However, if `P1` (resp. `P2`) is a polyhedron for which the V-representation has not been computed yet, it will trigger a representation conversion which is costly.

The type of the result will be chosen closer to the type of `P1`. For instance, if `P1` is a polyhedron (resp. V-representation) and `P2` is a V-representation (resp. polyhedron), `convexhull(P1, P2)` will be a polyhedron (resp. V-representation).
If `P1` and `P2` are both polyhedra (resp. V-representation), the resulting polyhedron type (resp. V-representation type) will be computed according to the type of `P1`.
The coefficient type however, will be promoted as required taking both the coefficient type of `P1` and `P2` into account.
"""
function convexhull(p1::RepTin, p2::VRep{N, T2}) where {N, T1, T2, RepTin<:VRep{N, T1}}
    Tout = promote_type(T1, T2)
    # Always type of first arg
    RepTout = lazychangeeltype(RepTin, Tout)
    RepTout(VRepIterator([VRep{N, Tout}(p1), VRep{N, Tout}(p2)]))
end

function (+)(p1::RepTin, p2::VRep{N, T2}) where {N, T1, T2, RepTin<:VRep{N, T1}}
    Tout = promote_type(T1, T2)
    # Always type of first arg
    RepTout = lazychangeeltype(RepTin, Tout)
    ps = PointsHull{N, Tout}([po1 + po2 for po1 in points(p1) for po2 in points(p2)])
    rs = RaysHull(AbstractRay{N, Tout}[collect(rays(p1)); collect(rays(p2))])
    RepTout(points(ps), rays(rs))
end

# p1 has priority
function usehrep(p1::Polyhedron, p2::Polyhedron)
    hrepiscomputed(p1) && (!vrepiscomputed(p1) || hrepiscomputed(p2))
end

function hcartesianproduct(p1::RepT1, p2::RepT2) where {N1, N2, T, RepT1<:HRep{N1, T}, RepT2<:HRep{N2, T}}
    Nout = N1 + N2
    # Always type of first arg
    RepTout = changefulldim(RepT1, Nout)
    f = (i, x) -> zeropad(x, i == 1 ? N2 : -N1)
    # TODO fastdecompose
    # FIXME Nin, Tin are only the N and T of p1. This does not make sense.
    #       Do we really need these 2 last parameters ? I guess we should remove them
    RepTout(HRepIterator{Nout, T, N1, T}([p1, p2], f))
end
function vcartesianproduct(p1::RepT1, p2::RepT2) where {N1, N2, T, RepT1<:VRep{N1, T}, RepT2<:VRep{N2, T}}
    Nout = N1 + N2
    # Always type of first arg
    RepTout = changefulldim(RepT1, Nout)
    f1 = (i, x) -> zeropad(x, N2)
    f2 = (i, x) -> zeropad(x, -N1)
    # TODO fastdecompose
    # FIXME Nin, Tin are only the N and T of p1. This does not make sense.
    #       Do we really need these 2 last parameters ? I guess we should remove them
    q1 = changefulldim(RepT1, Nout)(VRepIterator{Nout, T, N1, T}([p1], f1))
    q2 = changefulldim(RepT2, Nout)(VRepIterator{Nout, T, N2, T}([p2], f2))
    q1 + q2
end
(*)(p1::HRep, p2::HRep) = hcartesianproduct(p1, p2)
(*)(p1::VRep, p2::VRep) = vcartesianproduct(p1, p2)
function (*)(p1::Polyhedron, p2::Polyhedron)
    if usehrep(p1, p2)
        hcartesianproduct(p1, p2)
    else
        vcartesianproduct(p1, p2)
    end
end

"""
    \\(P::AbstractMatrix, p::HRep)

Transform the polyhedron represented by ``p`` into ``P^{-1} p`` by transforming each halfspace ``\\langle a, x \\rangle \\le \\beta`` into ``\\langle P^\\top a, x \\rangle \\le \\beta`` and each hyperplane ``\\langle a, x \\rangle = \\beta`` into ``\\langle P^\\top a, x \\rangle = \\beta``.
"""
(\)(P::AbstractMatrix, rep::HRep) = rep / P'

"""
    /(p::HRep, P::AbstractMatrix)

Transform the polyhedron represented by ``p`` into ``P^{-T} p`` by transforming each halfspace ``\\langle a, x \\rangle \\le \\beta`` into ``\\langle P a, x \\rangle \\le \\beta`` and each hyperplane ``\\langle a, x \\rangle = \\beta`` into ``\\langle P a, x \\rangle = \\beta``.
"""
function (/)(rep::RepT, P::AbstractMatrix) where RepT<:HRep
    Nin = fulldim(rep)
    Tin = eltype(rep)
    if size(P, 1) != Nin
        error("The number of rows of P must match the dimension of the H-representation")
    end
    Nout = size(P, 2)
    Tout = mypromote_type(eltype(RepT), eltype(P))
    if RepT <: HRepresentation
        RepTout = lazychangeboth(RepT, Nout, Tout)
    end
    f = (i, h) -> h / P
    if decomposedhfast(rep)
        eqs = EqIterator{Nout,Tout,Nin,Tin}([rep], f)
        ineqs = IneqIterator{Nout,Tout,Nin,Tin}([rep], f)
        if RepT <: HRepresentation
            RepTout(eqs, ineqs)
        else
            polyhedron(ineqs, eqs, getlibraryfor(rep, Nout, Tout))
        end
    else
        hreps = HRepIterator{Nout,Tout,Nin,Tin}([rep], f)
        if RepT <: HRepresentation
            RepTout(hreps)
        else
            polyhedron(hreps, getlibraryfor(rep, Nout, Tout))
        end
    end
end

(*)(rep::HRep, P::AbstractMatrix) = warn("`*(p::HRep, P::AbstractMatrix)` is deprecated. Use `P \\ p` or `p / P'` instead.")

"""
    *(P::AbstractMatrix, p::HRep)

Transform the polyhedron represented by ``p`` into ``P p`` by transforming each element of the V-representation (points, symmetric points, rays and lines) `x` into ``P x``.
"""
function (*)(P::AbstractMatrix, rep::RepT) where RepT<:VRep
    Nin = fulldim(rep)
    Tin = eltype(rep)
    if size(P, 2) != Nin
        error("The number of rows of P must match the dimension of the H-representation")
    end
    Nout = size(P, 1)
    Tout = mypromote_type(eltype(RepT), eltype(P))
    RepTout = changeboth(RepT, Nout, Tout)
    f = (i, v) -> P * v
    if decomposedvfast(rep)
        points = PointIterator{Nout,Tout,Nin,Tin}([rep], f)
        rays = RayIterator{Nout,Tout,Nin,Tin}([rep], f)
        if RepT <: VRepresentation
            RepTout(points, rays)
        else
            polyhedron(points, rays, getlibraryfor(rep, Nout, Tout))
        end
    else
        vreps = VRepIterator{Nout,Tout,Nin,Tin}([rep], f)
        if RepT <: VRepresentation
            RepTout(vreps)
        else
            polyhedron(vreps, getlibraryfor(rep, Nout, Tout))
        end
    end
end
