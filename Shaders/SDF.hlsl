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

/// Signed distance to an infinite plane through the origin.
/// @param p Sample point.
/// @param n Plane normal, must be normalized.
/// @return Signed distance to the plane (negative below, positive above).
float SdPlane(float3 p, float3 n)
{
    return dot(p, n);
}

// --- Boolean operators ---
// Combine two signed distances. min() stays an exact SDF for union; max()-based
// subtraction and intersection can slightly overestimate distance near seams.

/// Union of two shapes (logical OR).
float OpUnion(float a, float b) { return min(a, b); }

/// Subtracts shape b from shape a.
float OpSubtract(float a, float b) { return max(a, -b); }

/// Intersection of two shapes (logical AND).
float OpIntersect(float a, float b) { return max(a, b); }

/// Polynomial smooth minimum. Merges two distance fields over a blend band of
/// width k instead of a hard crease.
/// @param a First distance.
/// @param b Second distance.
/// @param k Blend radius in world units.
/// @return Smoothly merged distance.
float Smin(float a, float b, float k)
{
    float h = saturate(0.5 + 0.5 * (b - a) / k);
    return lerp(b, a, h) - k * h * (1.0 - h);
}

/// Smooth union of two shapes.
float OpSmoothUnion(float a, float b, float k) { return Smin(a, b, k); }

/// Smooth subtraction of shape b from shape a.
float OpSmoothSubtract(float a, float b, float k) { return -Smin(-a, b, k); }

/// Smooth intersection of two shapes.
float OpSmoothIntersect(float a, float b, float k) { return -Smin(-a, -b, k); }

// --- Domain operators ---
// These transform the sample point p before it is passed to a primitive.

/// Tiles space infinitely: one primitive becomes an endless grid of copies.
/// @param p Sample point.
/// @param period Cell size along each axis.
/// @return Point wrapped into the base cell.
float3 OpRepeat(float3 p, float3 period)
{
    return p - period * round(p / period);
}

/// Twists space around the Y axis (helix-like shear).
/// @param p Sample point.
/// @param strength Twist in radians per unit of height.
/// @return Deformed point.
float3 OpTwist(float3 p, float strength)
{
    float a = strength * p.y;
    float c = cos(a);
    float s = sin(a);
    return float3(c * p.x - s * p.z, p.y, s * p.x + c * p.z);
}

/// Bends space around the Z axis (arch-like deformation).
/// @param p Sample point.
/// @param strength Bend in radians per unit of X.
/// @return Deformed point.
float3 OpBend(float3 p, float strength)
{
    float a = strength * p.x;
    float c = cos(a);
    float s = sin(a);
    return float3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
}

#endif // COLESLOW_SDF_INCLUDED

// --- Raymarching ---
// This layer is re-evaluated on every include. Include SDF.hlsl once for the
// primitives, write a scene function using them, then include again with the
// scene macro defined:
//   #include ".../SDF.hlsl"
//   float MyScene(float3 p) { return SdSphere(p, 1.0); }
//   #define COLESLOW_SDF_SCENE(p) MyScene(p)
//   #include ".../SDF.hlsl"   // now Raymarch(), SdfSceneNormal(), SdfSoftShadow()

#if defined(COLESLOW_SDF_SCENE) && !defined(COLESLOW_SDF_RAYMARCH_INCLUDED)
#define COLESLOW_SDF_RAYMARCH_INCLUDED

/// Surface normal of the scene at p, from central differences of the distance field.
/// @param p Point on or near the surface.
/// @return Normalized surface normal.
float3 SdfSceneNormal(float3 p)
{
    float2 e = float2(0.0005, 0.0);
    return normalize(float3(
        COLESLOW_SDF_SCENE(p + e.xyy) - COLESLOW_SDF_SCENE(p - e.xyy),
        COLESLOW_SDF_SCENE(p + e.yxy) - COLESLOW_SDF_SCENE(p - e.yxy),
        COLESLOW_SDF_SCENE(p + e.yyx) - COLESLOW_SDF_SCENE(p - e.yyx)));
}

/// Result of a raymarch query.
struct SdfHit
{
    bool hit;    // true if the ray reached the surface within maxDist
    float t;     // distance travelled along the ray
    float3 pos;  // hit position (ro + rd * t)
    int steps;   // iterations used, useful for cost visualization
};

/// Sphere-traces a ray through COLESLOW_SDF_SCENE.
/// @param ro Ray origin.
/// @param rd Ray direction, normalized.
/// @param maxSteps Iteration cap.
/// @param minDist Surface hit threshold.
/// @param maxDist Far clip along the ray.
/// @return Hit info (see SdfHit).
SdfHit Raymarch(float3 ro, float3 rd, int maxSteps, float minDist, float maxDist)
{
    SdfHit result;
    result.hit = false;
    result.t = 0.0;
    result.steps = 0;

    [loop]
    for (int i = 0; i < maxSteps; i++)
    {
        float3 p = ro + rd * result.t;
        float d = COLESLOW_SDF_SCENE(p);
        result.steps = i + 1;
        if (d < minDist)
        {
            result.hit = true;
            break;
        }
        result.t += d;
        if (result.t > maxDist)
            break;
    }

    result.pos = ro + rd * result.t;
    return result;
}

/// Soft shadow factor by marching from a surface point toward a light.
/// @param p Surface point (offset it slightly along the normal before calling).
/// @param lightDir Direction to the light, normalized.
/// @param maxDist Distance to the light.
/// @param sharpness Higher = harder penumbra (typical 8-64).
/// @return Shadow attenuation in [0, 1]; 1 = fully lit.
float SdfSoftShadow(float3 p, float3 lightDir, float maxDist, float sharpness)
{
    float shadow = 1.0;
    float t = 0.02;
    [loop]
    for (int i = 0; i < 48 && t < maxDist; i++)
    {
        float d = COLESLOW_SDF_SCENE(p + lightDir * t);
        if (d < 0.001)
            return 0.0;
        shadow = min(shadow, sharpness * d / t);
        t += d;
    }
    return saturate(shadow);
}

#endif // raymarch layer
