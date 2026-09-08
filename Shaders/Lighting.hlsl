#ifndef COLESLOW_LIGHTING_INCLUDED
#define COLESLOW_LIGHTING_INCLUDED

#ifndef PI
#define PI 3.14159265359
#endif

// Analytic BRDF terms for direct lighting. Each function returns a bare factor;
// multiply by light color, intensity and shadow/attenuation outside.

/// Lambertian diffuse term.
/// @param normal Surface normal, normalized.
/// @param lightDir Direction to the light, normalized.
/// @return Diffuse factor in [0, 1].
float DiffuseLambert(float3 normal, float3 lightDir)
{
    return saturate(dot(normal, lightDir));
}

/// Wrapped diffuse: pushes light past the terminator for a soft, cheap
/// approximation of subsurface scattering or bounced fill light.
/// @param normal Surface normal, normalized.
/// @param lightDir Direction to the light, normalized.
/// @param wrap Wrap amount in [0, 1]; 0 = Lambert, 1 = fully wrapped.
/// @return Diffuse factor in [0, 1].
float DiffuseWrapped(float3 normal, float3 lightDir, float wrap)
{
    float d = (dot(normal, lightDir) + wrap) / (1.0 + wrap);
    return saturate(d);
}

/// Oren-Nayar diffuse for rough matte surfaces (clay, concrete, fabric).
/// @param normal Surface normal, normalized.
/// @param lightDir Direction to the light, normalized.
/// @param viewDir Direction to the camera, normalized.
/// @param roughness Surface roughness in [0, 1].
/// @return Diffuse factor in [0, 1].
float DiffuseOrenNayar(float3 normal, float3 lightDir, float3 viewDir, float roughness)
{
    float NdotL = dot(normal, lightDir);
    float NdotV = dot(normal, viewDir);
    float s = roughness * roughness;
    float A = 1.0 - 0.5 * s / (s + 0.33);
    float B = 0.45 * s / (s + 0.09);
    float angleL = acos(clamp(NdotL, -1.0, 1.0));
    float angleV = acos(clamp(NdotV, -1.0, 1.0));
    float alpha = max(angleL, angleV);
    float beta = min(angleL, angleV);
    float3 lProj = normalize(lightDir - normal * NdotL);
    float3 vProj = normalize(viewDir - normal * NdotV);
    float cosPhi = saturate(dot(lProj, vProj));
    return saturate(NdotL) * (A + B * cosPhi * sin(alpha) * tan(beta));
}

/// GGX / Trowbridge-Reitz normal distribution function.
/// @param NdotH Cosine of the angle between normal and half vector.
/// @param roughness Perceptual roughness in [0, 1].
/// @return Microfacet distribution density.
float D_GGX(float NdotH, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float d = NdotH * NdotH * (a2 - 1.0) + 1.0;
    return a2 / max(PI * d * d, 1e-7);
}

/// Smith geometry term with the Schlick-GGX approximation, for direct lighting.
/// @param NdotV Cosine between normal and view direction.
/// @param NdotL Cosine between normal and light direction.
/// @param roughness Perceptual roughness in [0, 1].
/// @return Geometric shadowing/masking factor in [0, 1].
float G_SmithSchlick(float NdotV, float NdotL, float roughness)
{
    float r = roughness + 1.0;
    float k = r * r / 8.0;
    float gv = NdotV / (NdotV * (1.0 - k) + k);
    float gl = NdotL / (NdotL * (1.0 - k) + k);
    return gv * gl;
}

/// Schlick Fresnel with a roughness-aware ceiling, for image-based lighting.
/// @param cosTheta Cosine of the angle between normal and view direction.
/// @param F0 Reflectance at normal incidence (RGB).
/// @param roughness Perceptual roughness in [0, 1].
/// @return Fresnel reflectance (RGB).
float3 FresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    float3 ceiling = max(F0, (1.0 - roughness).xxx);
    return F0 + (ceiling - F0) * pow(1.0 - saturate(cosTheta), 5.0);
}

/// Full Cook-Torrance specular BRDF for one light, already multiplied by NdotL.
/// Add a diffuse term and the light color/intensity outside this function.
/// @param normal Surface normal, normalized.
/// @param viewDir Direction to the camera, normalized.
/// @param lightDir Direction to the light, normalized.
/// @param F0 Specular reflectance at normal incidence (0.04 dielectric, albedo for metal).
/// @param roughness Perceptual roughness in [0, 1].
/// @return Specular radiance factor (RGB), not including light color.
float3 SpecularCookTorrance(float3 normal, float3 viewDir, float3 lightDir, float3 F0, float roughness)
{
    float3 h = normalize(viewDir + lightDir);
    float NdotV = saturate(dot(normal, viewDir));
    float NdotL = saturate(dot(normal, lightDir));
    float NdotH = saturate(dot(normal, h));
    float VdotH = saturate(dot(viewDir, h));

    float D = D_GGX(NdotH, roughness);
    float G = G_SmithSchlick(NdotV, NdotL, roughness);
    float3 F = F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);

    return (D * G * F) / max(4.0 * NdotV * NdotL, 1e-4) * NdotL;
}

#endif
