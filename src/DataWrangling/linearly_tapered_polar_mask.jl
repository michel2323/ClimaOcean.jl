import ClimaOcean: stateindex

struct LinearlyTaperedPolarMask{N, S, Z}
    northern :: N
    southern :: S
    z :: Z
end

"""
    LinearlyTaperedPolarMask(; northern = (70,   75),
                               southern = (-75, -70),
                               z = (-20, 0))

Build a mask that is linearly tapered in latitude between the northern and southern edges.
The mask is constant in depth between the z and equals zero everywhere else.
The mask is limited to lie between (0, 1).
The mask has the following functional form:

```julia
n = 1 / (northern[2] - northern[1]) * (φ - northern[1])
s = 1 / (southern[1] - southern[2]) * (φ - southern[2])

valid_depth = (z[1] < z < z[2])

mask = valid_depth ? clamp(max(n, s), 0, 1) : 0
```
"""
function LinearlyTaperedPolarMask(; northern = (70,   75),
                                    southern = (-75, -70),
                                    z = (-20, 0))

    northern[1] > northern[2]  && throw(ArgumentError("Northern latitude range is invalid, northern[1] > northern[2]."))
    southern[1] > southern[2]  && throw(ArgumentError("Southern latitude range is invalid, southern[1] > southern[2]."))
    z[1] > z[2]                && throw(ArgumentError("Depth range is invalid, z[1] > z[2]."))

    return LinearlyTaperedPolarMask(northern, southern, z)
end

@inline function (mask::LinearlyTaperedPolarMask)(φ, z)
    n = 1 / (mask.northern[2] - mask.northern[1]) * (φ - mask.northern[1])
    s = 1 / (mask.southern[1] - mask.southern[2]) * (φ - mask.southern[2])

    # The mask is active only between `mask.z[1]` and `mask.z[2]`
    valid_depth = (mask.z[1] < z < mask.z[2])

    # we clamp the mask between 0 and 1
    mask_value = clamp(max(n, s), 0, 1)

    return ifelse(valid_depth, mask_value, zero(n))
end

@inline function stateindex(mask::LinearlyTaperedPolarMask, i, j, k, grid, time, loc)
    LX, LY, LZ = loc
    λ, φ, z = node(i, j, k, grid, LX(), LY(), LZ())
    return mask(φ, z)
end
