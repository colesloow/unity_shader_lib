#ifndef COLESLOW_SG_LIGHTING_INCLUDED
#define COLESLOW_SG_LIGHTING_INCLUDED

// Shader Graph wrapper layer for com.coleslow.shaderlib (Lighting module).
// See ShaderGraph/README.md for the convention and how to add a node.
// Every function returns a bare factor: multiply by light color / intensity /
// shadow outside the node. Useful for custom lighting in Unlit graphs.

#include "Packages/com.coleslow.shaderlib/Shaders/Lighting.hlsl"

void DiffuseLambert_float(float3 Normal, float3 LightDir, out float Out) { Out = DiffuseLambert(Normal, LightDir); }
void DiffuseLambert_half(half3 Normal, half3 LightDir, out half Out)     { Out = DiffuseLambert(Normal, LightDir); }

void DiffuseWrapped_float(float3 Normal, float3 LightDir, float Wrap, out float Out) { Out = DiffuseWrapped(Normal, LightDir, Wrap); }
void DiffuseWrapped_half(half3 Normal, half3 LightDir, half Wrap, out half Out)      { Out = DiffuseWrapped(Normal, LightDir, Wrap); }

void DiffuseOrenNayar_float(float3 Normal, float3 LightDir, float3 ViewDir, float Roughness, out float Out)
{
    Out = DiffuseOrenNayar(Normal, LightDir, ViewDir, Roughness);
}
void DiffuseOrenNayar_half(half3 Normal, half3 LightDir, half3 ViewDir, half Roughness, out half Out)
{
    Out = DiffuseOrenNayar(Normal, LightDir, ViewDir, Roughness);
}

void DistributionGGX_float(float NdotH, float Roughness, out float Out) { Out = DistributionGGX(NdotH, Roughness); }
void DistributionGGX_half(half NdotH, half Roughness, out half Out)     { Out = DistributionGGX(NdotH, Roughness); }

void GeometrySmithGGX_float(float NdotV, float NdotL, float Roughness, out float Out) { Out = GeometrySmithGGX(NdotV, NdotL, Roughness); }
void GeometrySmithGGX_half(half NdotV, half NdotL, half Roughness, out half Out)      { Out = GeometrySmithGGX(NdotV, NdotL, Roughness); }

void FresnelSchlickRoughness_float(float CosTheta, float3 F0, float Roughness, out float3 Out)
{
    Out = FresnelSchlickRoughness(CosTheta, F0, Roughness);
}
void FresnelSchlickRoughness_half(half CosTheta, half3 F0, half Roughness, out half3 Out)
{
    Out = FresnelSchlickRoughness(CosTheta, F0, Roughness);
}

// Cook-Torrance specular for one light, already multiplied by NdotL.
void SpecularCookTorrance_float(float3 Normal, float3 ViewDir, float3 LightDir, float3 F0, float Roughness, out float3 Out)
{
    Out = SpecularCookTorrance(Normal, ViewDir, LightDir, F0, Roughness);
}
void SpecularCookTorrance_half(half3 Normal, half3 ViewDir, half3 LightDir, half3 F0, half Roughness, out half3 Out)
{
    Out = SpecularCookTorrance(Normal, ViewDir, LightDir, F0, Roughness);
}

#endif
