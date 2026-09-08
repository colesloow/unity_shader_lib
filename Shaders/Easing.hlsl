#ifndef COLESLOW_EASING_INCLUDED
#define COLESLOW_EASING_INCLUDED

#ifndef PI
#define PI 3.14159265359
#endif

// Interpolation and shaping curves. All take a normalized input; most return a
// value in [0, 1] (elastic overshoots by design).

/// Quintic smoothstep (Ken Perlin). Zero first and second derivatives at both
/// ends, so it tiles and animates without visible seams.
/// @param t Input, clamped to [0, 1].
/// @return Eased value in [0, 1].
float SmootherStep(float t)
{
    t = saturate(t);
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

/// Cubic ease in-out.
/// @param t Input in [0, 1].
/// @return Eased value in [0, 1].
float EaseInOutCubic(float t)
{
    t = saturate(t);
    return t < 0.5 ? 4.0 * t * t * t : 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0;
}

/// Elastic ease out: overshoots, then settles with a decaying oscillation.
/// @param t Input in [0, 1].
/// @return Eased value; exceeds [0, 1] mid-curve.
float EaseOutElastic(float t)
{
    t = saturate(t);
    if (t <= 0.0 || t >= 1.0)
        return t;
    float c4 = (2.0 * PI) / 3.0;
    return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0;
}

/// Bounce ease out: settles like a dropped ball.
/// @param t Input in [0, 1].
/// @return Eased value in [0, 1].
float EaseOutBounce(float t)
{
    t = saturate(t);
    const float n1 = 7.5625;
    const float d1 = 2.75;
    if (t < 1.0 / d1)
        return n1 * t * t;
    if (t < 2.0 / d1)
    {
        t -= 1.5 / d1;
        return n1 * t * t + 0.75;
    }
    if (t < 2.5 / d1)
    {
        t -= 2.25 / d1;
        return n1 * t * t + 0.9375;
    }
    t -= 2.625 / d1;
    return n1 * t * t + 0.984375;
}

/// Symmetric contrast curve (Inigo Quilez "gain"). Pushes values toward 0 and 1
/// when k > 1, toward 0.5 when k < 1, identity at k = 1.
/// @param t Input in [0, 1].
/// @param k Contrast exponent (> 0).
/// @return Reshaped value in [0, 1].
float Gain(float t, float k)
{
    float a = 0.5 * pow(2.0 * ((t < 0.5) ? t : 1.0 - t), k);
    return (t < 0.5) ? a : 1.0 - a;
}

/// Smooth pulse: rises from 0 to 1 at edge0 and falls back to 0 at edge1.
/// @param edge0 Rising edge position.
/// @param edge1 Falling edge position.
/// @param x Input value.
/// @return Window value in [0, 1].
float Pulse(float edge0, float edge1, float x)
{
    float mid = lerp(edge0, edge1, 0.5);
    return smoothstep(edge0, mid, x) - smoothstep(mid, edge1, x);
}

#endif
