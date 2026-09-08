#ifndef COLESLOW_SDF_INCLUDED
#define COLESLOW_SDF_INCLUDED

// Signed distance functions for common primitives, after Inigo Quilez.
// All functions return the signed distance from point p to the surface:
// negative inside, positive outside, zero on the surface. Each primitive is
// centered at the origin; translate or rotate p before calling to place it.

/// Signed distance to a sphere.
/// @param p Sample point.
/// @param radius Sphere radius.
/// @return Signed distance to the sphere surface.
float SdSphere(float3 p, float radius)
{
    return length(p) - radius;
}

/// Signed distance to an axis-aligned box.
/// @param p Sample point.
/// @param halfExtents Half-size of the box along each axis.
/// @return Signed distance to the box surface.
float SdBox(float3 p, float3 halfExtents)
{
    float3 q = abs(p) - halfExtents;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

/// Signed distance to a torus lying in the XZ plane.
/// @param p Sample point.
/// @param majorRadius Distance from the center to the tube center.
/// @param minorRadius Tube radius.
/// @return Signed distance to the torus surface.
float SdTorus(float3 p, float majorRadius, float minorRadius)
{
    float2 q = float2(length(p.xz) - majorRadius, p.y);
    return length(q) - minorRadius;
}

/// Signed distance to a capsule (line segment with rounded ends).
/// @param p Sample point.
/// @param a Segment start point.
/// @param b Segment end point.
/// @param radius Capsule radius.
/// @return Signed distance to the capsule surface.
float SdCapsule(float3 p, float3 a, float3 b, float radius)
{
    float3 pa = p - a;
    float3 ba = b - a;
    float h = saturate(dot(pa, ba) / dot(ba, ba));
    return length(pa - ba * h) - radius;
}

#endif
