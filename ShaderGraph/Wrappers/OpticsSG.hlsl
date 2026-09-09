#ifndef COLESLOW_SG_OPTICS_INCLUDED
#define COLESLOW_SG_OPTICS_INCLUDED

// Shader Graph wrapper layer for com.coleslow.shaderlib (Optics module).
// See ShaderGraph/README.md for the convention and how to add a node.
// FresnelSchlick is omitted: use the native Fresnel Effect node.

#include "Packages/com.coleslow.shaderlib/Shaders/Optics.hlsl"

// Optical path difference (nm) for a thin film at a given viewing angle.
// CosIncidence = dot(normal, viewDir).
void ThinFilmOPD_float(float CosIncidence, float FilmIndex, float Thickness, out float Out)
{
    Out = ThinFilmOPD(CosIncidence, FilmIndex, Thickness);
}
void ThinFilmOPD_half(half CosIncidence, half FilmIndex, half Thickness, out half Out)
{
    Out = ThinFilmOPD(CosIncidence, FilmIndex, Thickness);
}

// Single-wavelength reflectance of the film. Feed OPD from ThinFilmOPD.
void ThinFilmReflectance_float(float OpticalPathDiff, float Wavelength, out float Out)
{
    Out = ThinFilmReflectance(OpticalPathDiff, Wavelength);
}
void ThinFilmReflectance_half(half OpticalPathDiff, half Wavelength, out half Out)
{
    Out = ThinFilmReflectance(OpticalPathDiff, Wavelength);
}

// Full spectral integration -> RGB iridescence filter. Multiply a reflection by it.
void SpectralFilter_float(float OpticalPathDiff, out float3 Out) { Out = SpectralFilter(OpticalPathDiff); }
void SpectralFilter_half(half OpticalPathDiff, out half3 Out)    { Out = SpectralFilter(OpticalPathDiff); }

#endif
