#ifndef COLESLOW_UV_INCLUDED
#define COLESLOW_UV_INCLUDED

#ifndef PI
#define PI 3.14159265359
#endif

/// Rotates UV coordinates around a pivot.
/// @param uv Input coordinates.
/// @param angle Rotation in radians.
/// @param center Pivot point (0.5 for the texture center).
/// @return Rotated coordinates.
float2 RotateUV(float2 uv, float angle, float2 center)
{
    float c = cos(angle);
    float s = sin(angle);
    uv -= center;
    uv = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    return uv + center;
}

/// Scales UVs about a pivot (zoom).
/// @param uv Input coordinates.
/// @param scale Per-axis scale factor.
/// @param center Pivot point.
/// @return Scaled coordinates.
float2 ScaleUV(float2 uv, float2 scale, float2 center)
{
    return (uv - center) / scale + center;
}

/// Converts Cartesian UV to polar coordinates around a center.
/// @param uv Input coordinates.
/// @param center Origin of the polar system.
/// @return x = radius, y = angle in [0, 1) (0 = +X, counter-clockwise).
float2 ToPolar(float2 uv, float2 center)
{
    float2 d = uv - center;
    float radius = length(d);
    float angle = atan2(d.y, d.x) / (2.0 * PI);
    return float2(radius, frac(angle));
}

/// Converts polar coordinates back to Cartesian UV.
/// @param polar x = radius, y = angle in turns [0, 1).
/// @param center Origin of the polar system.
/// @return Cartesian coordinates.
float2 FromPolar(float2 polar, float2 center)
{
    float angle = polar.y * 2.0 * PI;
    return center + float2(cos(angle), sin(angle)) * polar.x;
}

/// Triplanar texture blend. Samples a texture once per world axis and blends by
/// the world normal, removing stretching on unwrapped or procedural geometry.
/// Requires shader model 4.0+ (Texture2D / SamplerState objects).
/// @param tex Texture to sample.
/// @param samp Sampler state for tex.
/// @param worldPos Fragment world position.
/// @param worldNormal Fragment world normal, normalized.
/// @param scale World-space tiling scale.
/// @param sharpness Blend contrast; higher = tighter transitions (typical 1-8).
/// @return Blended RGBA sample.
float4 Triplanar(Texture2D tex, SamplerState samp, float3 worldPos, float3 worldNormal, float scale, float sharpness)
{
    float3 blend = pow(abs(worldNormal), sharpness);
    blend /= max(blend.x + blend.y + blend.z, 1e-5);
    float4 xProj = tex.Sample(samp, worldPos.yz * scale);
    float4 yProj = tex.Sample(samp, worldPos.xz * scale);
    float4 zProj = tex.Sample(samp, worldPos.xy * scale);
    return xProj * blend.x + yProj * blend.y + zProj * blend.z;
}

#endif
