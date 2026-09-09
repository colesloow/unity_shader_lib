#ifndef COLESLOW_SG_SPACETRANSFORMS_INCLUDED
#define COLESLOW_SG_SPACETRANSFORMS_INCLUDED

// Shader Graph wrapper layer for com.coleslow.shaderlib (SpaceTransforms module).
// See ShaderGraph/README.md for the convention and how to add a node.
// Depth linearization and dithering are omitted: use the native Scene Depth
// (Eye / Linear01 modes) and Dither nodes.

#include "Packages/com.coleslow.shaderlib/Shaders/SpaceTransforms.hlsl"

// Reconstruct a world-space position from a raw depth sample.
// Reads UNITY_MATRIX_I_VP directly so the node needs no matrix input: it uses
// whichever camera is currently rendering, which is what fullscreen effects want.
// The 3-argument WorldPosFromDepth in Shaders/SpaceTransforms.hlsl stays available
// for code that must pass a specific matrix.
void WorldPosFromDepth_float(float2 ScreenUV, float RawDepth, out float3 Out)
{
    Out = WorldPosFromDepth(ScreenUV, RawDepth, UNITY_MATRIX_I_VP);
}
void WorldPosFromDepth_half(half2 ScreenUV, half RawDepth, out half3 Out)
{
    Out = WorldPosFromDepth(ScreenUV, RawDepth, UNITY_MATRIX_I_VP);
}

#endif
