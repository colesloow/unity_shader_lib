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

#endif
