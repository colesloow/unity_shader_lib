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

/// Returns a pseudo-random float in [0, 1) from a 2D point. For UV-space shader noise.
/// @param p Sample point (e.g. floor of a scaled UV).
/// @return Hash value in [0, 1).
float Hash12(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

/// Smooth value noise in 2D. Interpolates Hash12 values at the 4 corners of a unit cell.
/// @param p Continuous sample position (scale to control frequency).
/// @return Noise value in [0, 1).
float ValueNoise2D(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
    f = f * f * (3.0 - 2.0 * f); // smoothstep
    float n00 = Hash12(i + float2(0, 0));
    float n10 = Hash12(i + float2(1, 0));
    float n01 = Hash12(i + float2(0, 1));
    float n11 = Hash12(i + float2(1, 1));
    float nx0 = lerp(n00, n10, f.x);
    float nx1 = lerp(n01, n11, f.x);
    return lerp(nx0, nx1, f.y);
}

/// Fractional Brownian Motion in 2D: 4 octaves of ValueNoise2D with decreasing amplitude.
/// @param p Sample position. Scale before passing to control base frequency.
/// @return FBM value roughly in [0, 1).
float Fbm2D(float2 p)
{
    float sum = 0.0;
    float amp = 0.5;
    [unroll]
    for (int i = 0; i < 4; i++)
    {
        sum += ValueNoise2D(p) * amp;
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
