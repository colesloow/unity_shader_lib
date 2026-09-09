#ifndef COLESLOW_SG_SPACETRANSFORMS_INCLUDED
#define COLESLOW_SG_SPACETRANSFORMS_INCLUDED

// Shader Graph wrapper layer for com.coleslow.shaderlib (SpaceTransforms module).
// See ShaderGraph/README.md for the convention and how to add a node.
// Depth linearization and dithering are omitted: use the native Scene Depth
// (Eye / Linear01 modes) and Dither nodes.

#include "Packages/com.coleslow.shaderlib/Shaders/SpaceTransforms.hlsl"

// Reconstruct a world-space position from a raw depth sample.
// Feed InvViewProjection with the Matrix4x4 property bound to UNITY_MATRIX_I_VP
// (there is no built-in Shader Graph node exposing it).
// float only: a half precision matrix is not meaningful here.
void WorldPosFromDepth_float(float2 ScreenUV, float RawDepth, float4x4 InvViewProjection, out float3 Out)
{
    Out = WorldPosFromDepth(ScreenUV, RawDepth, InvViewProjection);
}

#endif
