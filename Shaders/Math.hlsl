#ifndef COLESLOW_MATH_INCLUDED
#define COLESLOW_MATH_INCLUDED

#ifndef PI
#define PI 3.14159265359
#endif

/// Rotates vector v around an arbitrary axis by a given angle (radians).
/// Uses Rodrigues' rotation formula.
/// @param v Vector to rotate.
/// @param axis Normalized rotation axis.
/// @param angle Angle in radians.
/// @return Rotated vector.
float3 RotateAboutAxis(float3 v, float3 axis, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return v * c + cross(axis, v) * s + axis * dot(axis, v) * (1.0 - c);
}

/// Rotates a direction vector around the Y axis.
/// @param dir Input direction.
/// @param turns Rotation amount in turns (0..1 = full circle).
/// @return Rotated direction.
float3 RotateY(float3 dir, float turns)
{
    float a = turns * 2.0 * PI;
    float c = cos(a);
    float s = sin(a);
    return float3(dir.x * c - dir.z * s, dir.y, dir.x * s + dir.z * c);
}

/// Rotates a direction vector around the X axis.
/// @param dir Input direction.
/// @param turns Rotation amount in turns (0..1 = full circle).
/// @return Rotated direction.
float3 RotateX(float3 dir, float turns)
{
    float a = turns * 2.0 * PI;
    float c = cos(a);
    float s = sin(a);
    return float3(dir.x, dir.y * c - dir.z * s, dir.y * s + dir.z * c);
}

/// Rotates a direction vector around the Z axis.
/// @param dir Input direction.
/// @param turns Rotation amount in turns (0..1 = full circle).
/// @return Rotated direction.
float3 RotateZ(float3 dir, float turns)
{
    float a = turns * 2.0 * PI;
    float c = cos(a);
    float s = sin(a);
    return float3(dir.x * c - dir.y * s, dir.x * s + dir.y * c, dir.z);
}

/// Linearly remaps a value from one range to another. Not clamped.
/// Named RemapRange rather than Remap to avoid colliding with URP/HDRP core,
/// which defines Remap() with a different argument order.
/// @param value Input value.
/// @param inMin Start of the input range.
/// @param inMax End of the input range.
/// @param outMin Start of the output range.
/// @param outMax End of the output range.
/// @return Remapped value.
float RemapRange(float value, float inMin, float inMax, float outMin, float outMax)
{
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin);
}

#endif
