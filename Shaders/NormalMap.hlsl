#ifndef COLESLOW_NORMALMAP_INCLUDED
#define COLESLOW_NORMALMAP_INCLUDED

#include "Noise.hlsl"

/// Decodes a Unity tangent-space normal map sample into a normal vector.
/// Handles both DXT5nm/BC5 (alpha or green stored) and plain RGB encodings.
/// @param packedNormal Raw texture sample from a normal map.
/// @param scale Normal intensity multiplier (bump strength).
/// @return Tangent-space normal, normalized, z pointing out of the surface.
float3 UnpackNormalScaled(float4 packedNormal, float scale)
{
    float3 normal;
    normal.xy = packedNormal.wy * 2.0 - 1.0;
    normal.xy *= scale;
    normal.z = sqrt(saturate(1.0 - dot(normal.xy, normal.xy)));
    return normal;
}

/// Decodes a Unity tangent-space normal map sample with unit intensity.
/// @param packedNormal Raw texture sample from a normal map.
/// @return Tangent-space normal, normalized.
float3 UnpackNormal(float4 packedNormal)
{
    return UnpackNormalScaled(packedNormal, 1.0);
}

/// Builds a tangent-space normal by sampling a height field via central finite differences.
/// @param uv Sample location.
/// @param height Height (bump) value at uv, in the same units the caller uses.
/// @param heightRight Height at uv + (epsilon, 0).
/// @param heightUp Height at uv + (0, epsilon).
/// @param epsilon Offset used for the samples (texel size or a small UV delta).
/// @param strength Bump strength multiplier.
/// @return Normalized tangent-space normal, z pointing out of the surface.
float3 NormalFromHeight(float2 uv, float height, float heightRight, float heightUp, float epsilon, float strength)
{
    float dhdx = (heightRight - height) / epsilon * strength;
    float dhdy = (heightUp - height) / epsilon * strength;
    return normalize(float3(-dhdx, -dhdy, 1.0));
}

/// Perturbs a tangent-space normal from procedural FBM noise using finite differences.
/// Useful for adding surface detail without a texture. Sample in the shader's UV or
/// world space depending on the look you want.
/// @param p Sample position (scale to control detail frequency).
/// @param epsilon Finite-difference offset. Smaller values pick up higher-frequency detail.
/// @param strength Bump strength multiplier.
/// @return Normalized tangent-space normal, z pointing out of the surface.
float3 NoiseNormal(float2 p, float epsilon, float strength)
{
    float h = Fbm2D(p);
    float hx = Fbm2D(p + float2(epsilon, 0.0));
    float hy = Fbm2D(p + float2(0.0, epsilon));
    float dhdx = (hx - h) / epsilon * strength;
    float dhdy = (hy - h) / epsilon * strength;
    return normalize(float3(-dhdx, -dhdy, 1.0));
}

#endif
