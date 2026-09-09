#ifndef COLESLOW_SG_COLOR_INCLUDED
#define COLESLOW_SG_COLOR_INCLUDED

// Shader Graph wrapper layer for com.coleslow.shaderlib (Color module).
// See ShaderGraph/README.md for the convention and how to add a node.
// RGB<->HSV, Linear<->Gamma and Blackbody are omitted: Shader Graph has
// native nodes for them (Colorspace Conversion, Blackbody).

#include "Packages/com.coleslow.shaderlib/Shaders/Color.hlsl"

// Asymmetric Gaussian lobe, used to approximate spectral response curves.
void Lobe_float(float X, float Mu, float SigmaLeft, float SigmaRight, out float Out)
{
    Out = Lobe(X, Mu, SigmaLeft, SigmaRight);
}
void Lobe_half(half X, half Mu, half SigmaLeft, half SigmaRight, out half Out)
{
    Out = Lobe(X, Mu, SigmaLeft, SigmaRight);
}

// CIE 1931 color matching functions: wavelength (nm) -> XYZ tristimulus.
void CIE1931_float(float Wavelength, out float3 XYZ) { XYZ = CIE1931(Wavelength); }
void CIE1931_half(half Wavelength, out half3 XYZ)    { XYZ = CIE1931(Wavelength); }

void XYZtoLinearSRGB_float(float3 XYZ, out float3 Out) { Out = XYZtoLinearSRGB(XYZ); }
void XYZtoLinearSRGB_half(half3 XYZ, out half3 Out)    { Out = XYZtoLinearSRGB(XYZ); }

// Convenience: wavelength (nm) straight to a displayable linear RGB color.
void WavelengthToRGB_float(float Wavelength, out float3 Out)
{
    Out = saturate(XYZtoLinearSRGB(CIE1931(Wavelength)));
}
void WavelengthToRGB_half(half Wavelength, out half3 Out)
{
    Out = saturate(XYZtoLinearSRGB(CIE1931(Wavelength)));
}

#endif
