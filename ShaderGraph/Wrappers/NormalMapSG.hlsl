#ifndef COLESLOW_SG_NORMALMAP_INCLUDED
#define COLESLOW_SG_NORMALMAP_INCLUDED

// Shader Graph wrapper layer for com.coleslow.shaderlib (NormalMap module).
// See ShaderGraph/README.md for the convention and how to add a node.
// DecodeNormalMap and NormalFromHeight are omitted: use the native
// Normal Unpack and Normal From Height nodes.

#include "Packages/com.coleslow.shaderlib/Shaders/NormalMap.hlsl"

// Tangent-space normal perturbed by procedural FBM, via finite differences.
// P is the sample position (scale to control detail frequency).
void NoiseNormal_float(float2 P, float Epsilon, float Strength, out float3 Out)
{
    Out = NoiseNormal(P, Epsilon, Strength);
}
void NoiseNormal_half(half2 P, half Epsilon, half Strength, out half3 Out)
{
    Out = NoiseNormal(P, Epsilon, Strength);
}

#endif
