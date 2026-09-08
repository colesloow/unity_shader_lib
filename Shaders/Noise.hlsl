#ifndef COLESLOW_NOISE_INCLUDED
#define COLESLOW_NOISE_INCLUDED

/// Returns a pseudo-random float in [0, 1) from a 3D integer lattice point.
/// @param p Lattice coordinate (typically floor of a world position).
/// @return Hash value in [0, 1).
float Hash13(float3 p)
{
    p = frac(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return frac((p.x + p.y) * p.z);
}

/// Smooth value noise in 3D. Interpolates Hash13 values at the 8 corners of a unit cube.
/// @param p Continuous sample position.
/// @return Noise value in [0, 1).
float ValueNoise(float3 p)
{
    float3 i = floor(p);
    float3 f = frac(p);
    f = f * f * (3.0 - 2.0 * f); // smoothstep
    float n000 = Hash13(i + float3(0, 0, 0));
    float n100 = Hash13(i + float3(1, 0, 0));
    float n010 = Hash13(i + float3(0, 1, 0));
    float n110 = Hash13(i + float3(1, 1, 0));
    float n001 = Hash13(i + float3(0, 0, 1));
    float n101 = Hash13(i + float3(1, 0, 1));
    float n011 = Hash13(i + float3(0, 1, 1));
    float n111 = Hash13(i + float3(1, 1, 1));
    float nx00 = lerp(n000, n100, f.x);
    float nx10 = lerp(n010, n110, f.x);
    float nx01 = lerp(n001, n101, f.x);
    float nx11 = lerp(n011, n111, f.x);
    float nxy0 = lerp(nx00, nx10, f.y);
    float nxy1 = lerp(nx01, nx11, f.y);
    return lerp(nxy0, nxy1, f.z);
}

/// Fractional Brownian Motion: 4 octaves of ValueNoise summed with decreasing amplitude.
/// @param p Sample position. Scale before passing to control frequency.
/// @return FBM value roughly in [0, 1).
float Fbm(float3 p)
{
    float sum = 0.0;
    float amp = 0.5;
    [unroll]
    for (int i = 0; i < 4; i++)
    {
        sum += ValueNoise(p) * amp;
        p *= 2.0;
        amp *= 0.5;
    }
    return sum;
}

/// Domain-warped FBM: a first FBM pass deforms the coordinates before the main FBM.
/// Produces organic swirling structures compared to plain FBM.
/// @param p Sample position.
/// @param warpAmount Strength of the coordinate deformation.
/// @return Warped FBM value roughly in [0, 1).
float FbmWarped(float3 p, float warpAmount)
{
    float warp = Fbm(p);
    return Fbm(p + warp * warpAmount);
}

#endif
