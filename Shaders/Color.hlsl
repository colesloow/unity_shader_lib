#ifndef COLESLOW_COLOR_INCLUDED
#define COLESLOW_COLOR_INCLUDED

/// Converts RGB to HSV. All components in [0, 1].
/// @param c Linear RGB color.
/// @return HSV: x = hue [0,1], y = saturation [0,1], z = value [0,1].
float3 RGBtoHSV(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

/// Converts HSV to RGB. All components in [0, 1].
/// @param c HSV: x = hue [0,1], y = saturation [0,1], z = value [0,1].
/// @return Linear RGB color.
float3 HSVtoRGB(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

/// Converts CIE XYZ to linear sRGB using the standard D65 matrix.
/// @param c XYZ tristimulus values.
/// @return Linear sRGB. May contain negative values for out-of-gamut colors; clamp if needed.
float3 XYZtoLinearSRGB(float3 c)
{
    return float3(
        dot(c, float3( 3.2406, -1.5372, -0.4986)),
        dot(c, float3(-0.9689,  1.8758,  0.0415)),
        dot(c, float3( 0.0557, -0.2040,  1.0570)));
}

/// Asymmetric Gaussian lobe. Used to approximate spectral response curves.
/// @param x Input value (e.g. wavelength in nm).
/// @param mu Peak position.
/// @param s1 Left sigma (x < mu).
/// @param s2 Right sigma (x >= mu).
/// @return Lobe value in (0, 1].
float Lobe(float x, float mu, float s1, float s2)
{
    float s = (x < mu) ? s1 : s2;
    float t = (x - mu) / s;
    return exp(-0.5 * t * t);
}

/// Approximates the CIE 1931 color matching functions (XYZ) for a given wavelength.
/// Lets you convert a physical wavelength to a perceptual RGB color without a lookup texture.
/// @param lambda Wavelength in nanometers. Meaningful range: 380-740 nm.
/// @return XYZ tristimulus values. Pass to XYZtoLinearSRGB() to get RGB.
float3 CIE1931(float lambda)
{
    float x = 1.056 * Lobe(lambda, 599.8, 37.9, 31.0)
            + 0.362 * Lobe(lambda, 442.0, 16.0, 26.7)
            - 0.065 * Lobe(lambda, 501.1, 20.4, 26.2);
    float y = 0.821 * Lobe(lambda, 568.8, 46.9, 40.5)
            + 0.286 * Lobe(lambda, 530.9, 16.3, 31.1);
    float z = 1.217 * Lobe(lambda, 437.0, 11.8, 36.0)
            + 0.681 * Lobe(lambda, 459.0, 26.0, 13.8);
    return float3(x, y, z);
}

/// Converts a linear color to gamma (sRGB) space using the exact sRGB transfer curve.
/// @param c Linear RGB color.
/// @return Gamma-encoded RGB color.
float3 LinearToGamma(float3 c)
{
    float3 lo = c * 12.92;
    float3 hi = 1.055 * pow(max(c, 0.0), 1.0 / 2.4) - 0.055;
    return lerp(hi, lo, step(c, 0.0031308));
}

/// Converts a gamma (sRGB) color to linear space using the exact sRGB transfer curve.
/// @param c Gamma-encoded RGB color.
/// @return Linear RGB color.
float3 GammaToLinear(float3 c)
{
    float3 lo = c / 12.92;
    float3 hi = pow(max(c + 0.055, 0.0) / 1.055, 2.4);
    return lerp(hi, lo, step(c, 0.04045));
}

/// Approximates the linear sRGB color of an ideal blackbody at a given temperature.
/// Uses a polynomial fit to the Planckian locus (valid roughly 1000-40000 K).
/// @param kelvin Temperature in Kelvin.
/// @return Linear RGB color, normalized so the brightest channel is 1.
float3 Blackbody(float kelvin)
{
    float t = clamp(kelvin, 1000.0, 40000.0) / 100.0;
    float r, g, b;

    if (t <= 66.0)
    {
        r = 1.0;
        g = saturate(0.39008157 * log(t) - 0.63184144);
    }
    else
    {
        r = saturate(1.29293618 * pow(t - 60.0, -0.1332047592));
        g = saturate(1.12989086 * pow(t - 60.0, -0.0755148492));
    }

    if (t >= 66.0)
        b = 1.0;
    else if (t <= 19.0)
        b = 0.0;
    else
        b = saturate(0.54320679 * log(t - 10.0) - 1.19625408);

    return float3(r, g, b);
}

#endif
