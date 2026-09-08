#ifndef COLESLOW_OPTICS_INCLUDED
#define COLESLOW_OPTICS_INCLUDED

#ifndef PI
#define PI 3.14159265359
#endif

#include "Color.hlsl"

/// Schlick's approximation of the Fresnel reflectance.
/// @param cosTheta Cosine of the angle between the surface normal and view direction.
/// @param F0 Reflectance at normal incidence (0.04 for glass/dielectrics, higher for metals).
/// @return Fresnel reflectance in [0, 1].
float FresnelSchlick(float cosTheta, float F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

/// Computes per-channel reflectance of a thin transparent film via wave interference.
/// Integrate over wavelengths and weight by CIE1931 to get an RGB filter (see SpectralFilter).
/// @param opticalPathDiff Optical path difference in nm: 2 * n * d * cos(theta_t).
/// @param lambda Wavelength to evaluate in nm (loop 380-740 for full spectrum).
/// @return Reflectance in [0, 1] for this wavelength.
float ThinFilmReflectance(float opticalPathDiff, float lambda)
{
    float r = sin(PI * opticalPathDiff / lambda);
    return r * r;
}

/// Computes the optical path difference for a thin film given viewing angle and film parameters.
/// Feed the result to ThinFilmReflectance() or SpectralFilter().
/// @param cosI Cosine of the angle of incidence (dot(normal, viewDir)).
/// @param filmIndex Refractive index of the film (e.g. 1.4 for soap, 1.5 for glass).
/// @param thickness Film thickness in nanometers.
/// @return Optical path difference in nanometers.
float ThinFilmOPD(float cosI, float filmIndex, float thickness)
{
    float sinI2 = 1.0 - cosI * cosI;
    float cosT = sqrt(saturate(1.0 - sinI2 / (filmIndex * filmIndex))); // Snell's law
    return 2.0 * filmIndex * thickness * cosT;
}

/// Converts thin-film optical path difference into an RGB color filter.
/// Integrates reflectance over the visible spectrum, weighted by human eye sensitivity (CIE 1931).
/// Multiply your reflection color by the returned filter to get iridescent coloring.
/// A very thin film returns near-black (destructive interference across all wavelengths).
/// @param opticalPathDiff Optical path difference in nm, from ThinFilmOPD().
/// @return RGB filter in [0, 1]. Multiply against a reflection to apply iridescence.
float3 SpectralFilter(float opticalPathDiff)
{
    float3 num = 0.0;
    float3 den = 0.0;
    const int SAMPLES = 32;
    [loop]
    for (int k = 0; k < SAMPLES; k++)
    {
        float lambda = lerp(380.0, 740.0, k / (float)(SAMPLES - 1));
        float refl = ThinFilmReflectance(opticalPathDiff, lambda);
        float3 resp = max(XYZtoLinearSRGB(CIE1931(lambda)), 0.0);
        num += resp * refl;
        den += resp;
    }
    return saturate(num / max(den, 1e-3));
}

#endif
