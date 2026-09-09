#ifndef COLESLOW_SG_SDF_INCLUDED
#define COLESLOW_SG_SDF_INCLUDED

// Shader Graph wrapper layer for com.coleslow.shaderlib (SDF module).
// See ShaderGraph/README.md for the convention and how to add a node.
// Primitives and operators only. The raymarcher is intentionally excluded:
// it needs a scene distance function defined in HLSL, which cannot be authored
// from a graph. Domain operators (Twist / Bend / Repeat) are easy follow-ups.

#include "Packages/com.coleslow.shaderlib/Shaders/SDF.hlsl"

// --- Primitives (Distance is signed: negative inside, positive outside) ---

void SdSphere_float(float3 P, float Radius, out float Distance) { Distance = SdSphere(P, Radius); }
void SdSphere_half(half3 P, half Radius, out half Distance)     { Distance = SdSphere(P, Radius); }

void SdBox_float(float3 P, float3 HalfExtents, out float Distance) { Distance = SdBox(P, HalfExtents); }
void SdBox_half(half3 P, half3 HalfExtents, out half Distance)     { Distance = SdBox(P, HalfExtents); }

void SdTorus_float(float3 P, float MajorRadius, float MinorRadius, out float Distance)
{
    Distance = SdTorus(P, MajorRadius, MinorRadius);
}
void SdTorus_half(half3 P, half MajorRadius, half MinorRadius, out half Distance)
{
    Distance = SdTorus(P, MajorRadius, MinorRadius);
}

void SdCapsule_float(float3 P, float3 PointA, float3 PointB, float Radius, out float Distance)
{
    Distance = SdCapsule(P, PointA, PointB, Radius);
}
void SdCapsule_half(half3 P, half3 PointA, half3 PointB, half Radius, out half Distance)
{
    Distance = SdCapsule(P, PointA, PointB, Radius);
}

void SdPlane_float(float3 P, float3 Normal, out float Distance) { Distance = SdPlane(P, Normal); }
void SdPlane_half(half3 P, half3 Normal, out half Distance)     { Distance = SdPlane(P, Normal); }

// --- Boolean operators (A and B are signed distances) ---

void OpUnion_float(float A, float B, out float Distance) { Distance = OpUnion(A, B); }
void OpUnion_half(half A, half B, out half Distance)     { Distance = OpUnion(A, B); }

void OpSubtract_float(float A, float B, out float Distance) { Distance = OpSubtract(A, B); }
void OpSubtract_half(half A, half B, out half Distance)     { Distance = OpSubtract(A, B); }

void OpIntersect_float(float A, float B, out float Distance) { Distance = OpIntersect(A, B); }
void OpIntersect_half(half A, half B, out half Distance)     { Distance = OpIntersect(A, B); }

// --- Smooth operators (K is the blend radius in world units) ---

void Smin_float(float A, float B, float K, out float Distance) { Distance = Smin(A, B, K); }
void Smin_half(half A, half B, half K, out half Distance)      { Distance = Smin(A, B, K); }

void OpSmoothUnion_float(float A, float B, float K, out float Distance) { Distance = OpSmoothUnion(A, B, K); }
void OpSmoothUnion_half(half A, half B, half K, out half Distance)      { Distance = OpSmoothUnion(A, B, K); }

void OpSmoothSubtract_float(float A, float B, float K, out float Distance) { Distance = OpSmoothSubtract(A, B, K); }
void OpSmoothSubtract_half(half A, half B, half K, out half Distance)      { Distance = OpSmoothSubtract(A, B, K); }

void OpSmoothIntersect_float(float A, float B, float K, out float Distance) { Distance = OpSmoothIntersect(A, B, K); }
void OpSmoothIntersect_half(half A, half B, half K, out half Distance)      { Distance = OpSmoothIntersect(A, B, K); }

#endif
