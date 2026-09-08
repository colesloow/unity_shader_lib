#ifndef COLESLOW_SPACETRANSFORMS_INCLUDED
#define COLESLOW_SPACETRANSFORMS_INCLUDED

// Screen-space and depth helpers for post-process and fullscreen shaders.
// Depth functions honor Unity's UNITY_REVERSED_Z when it is defined.

/// Linear eye-space depth from a raw perspective depth sample.
/// @param rawDepth Raw depth buffer value (platform native).
/// @param near Camera near plane distance.
/// @param far Camera far plane distance.
/// @return Distance from the camera along the view axis, in world units.
float LinearEyeDepthFromRaw(float rawDepth, float near, float far)
{
#if defined(UNITY_REVERSED_Z)
    rawDepth = 1.0 - rawDepth;
#endif
    return near * far / (far - rawDepth * (far - near));
}

/// Normalized linear depth: 0 at the near plane, 1 at the far plane.
/// @param rawDepth Raw depth buffer value (platform native).
/// @param near Camera near plane distance.
/// @param far Camera far plane distance.
/// @return Linear depth in [0, 1].
float LinearDepth01FromRaw(float rawDepth, float near, float far)
{
    return (LinearEyeDepthFromRaw(rawDepth, near, far) - near) / (far - near);
}

/// Reconstructs a world-space position from a raw depth sample.
/// Pass the inverse view-projection matrix (UNITY_MATRIX_I_VP in URP).
/// @param screenUV Screen UV in [0, 1] of the pixel.
/// @param rawDepth Raw depth buffer value at screenUV (platform native).
/// @param invViewProj Inverse of the view-projection matrix.
/// @return World-space position.
float3 WorldPosFromDepth(float2 screenUV, float rawDepth, float4x4 invViewProj)
{
#if defined(UNITY_REVERSED_Z)
    float ndcZ = rawDepth;
#else
    float ndcZ = rawDepth * 2.0 - 1.0;
#endif
    float4 ndc = float4(screenUV * 2.0 - 1.0, ndcZ, 1.0);
    float4 world = mul(invViewProj, ndc);
    return world.xyz / world.w;
}

/// 4x4 ordered Bayer dither threshold for a pixel.
/// @param pixelCoord Integer screen pixel coordinate (e.g. floor(screenPos.xy)).
/// @return Threshold in [0, 1), evenly spread across the 4x4 tile.
float Bayer4x4(float2 pixelCoord)
{
    int2 p = int2(fmod(abs(pixelCoord), 4.0));
    const float m[16] =
    {
        0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
        12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
        3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
        15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
    };
    return m[p.y * 4 + p.x];
}

/// Ordered-dither coverage test for stipple transparency or banding removal.
/// Feed the result to clip(): clip(DitherClip(alpha, floor(screenPos.xy))).
/// @param value Coverage in [0, 1].
/// @param pixelCoord Integer screen pixel coordinate.
/// @return value - threshold; negative means "discard this pixel".
float DitherClip(float value, float2 pixelCoord)
{
    return value - Bayer4x4(pixelCoord);
}

#endif
