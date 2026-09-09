#ifndef COLESLOW_SG_NOISE_INCLUDED
#define COLESLOW_SG_NOISE_INCLUDED

// Shader Graph wrapper layer for com.coleslow.shaderlib (Noise module).
// Each function is exposed as <Name>_float / <Name>_half so it can be dropped
// into a Custom Function node (File mode) and packaged as a Sub Graph.
// Only functions with no built-in Shader Graph equivalent are wrapped.
// See ShaderGraph/README.md for the convention and how to add a node.

#include "Packages/com.coleslow.shaderlib/Shaders/Noise.hlsl"

void Hash12_float(float2 P, out float Out) { Out = Hash12(P); }
void Hash12_half(half2 P, out half Out)    { Out = Hash12(P); }

void Hash13_float(float3 P, out float Out) { Out = Hash13(P); }
void Hash13_half(half3 P, out half Out)    { Out = Hash13(P); }

void Hash22_float(float2 P, out float2 Out) { Out = Hash22(P); }
void Hash22_half(half2 P, out half2 Out)    { Out = Hash22(P); }

void Hash33_float(float3 P, out float3 Out) { Out = Hash33(P); }
void Hash33_half(half3 P, out half3 Out)    { Out = Hash33(P); }

void Fbm_float(float3 P, out float Out) { Out = Fbm(P); }
void Fbm_half(half3 P, out half Out)    { Out = Fbm(P); }

void Fbm2D_float(float2 UV, out float Out) { Out = Fbm2D(UV); }
void Fbm2D_half(half2 UV, out half Out)    { Out = Fbm2D(UV); }

void FbmWarped_float(float3 P, float WarpAmount, out float Out) { Out = FbmWarped(P, WarpAmount); }
void FbmWarped_half(half3 P, half WarpAmount, out half Out)     { Out = FbmWarped(P, WarpAmount); }

// F1 = distance to nearest feature point, F2 = distance to second nearest.
// F2 - F1 traces the cell borders (Worley crackle).
void Voronoi2D_float(float2 UV, float Jitter, out float F1, out float F2)
{
    float2 v = Voronoi2D(UV, Jitter);
    F1 = v.x;
    F2 = v.y;
}
void Voronoi2D_half(half2 UV, half Jitter, out half F1, out half F2)
{
    half2 v = Voronoi2D(UV, Jitter);
    F1 = v.x;
    F2 = v.y;
}

#endif
