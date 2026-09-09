# unity_shader_lib

A modular HLSL shader library for Unity.

## Modules

| File | Contents |
|---|---|
| `Shaders/Noise.hlsl` | Hash13, Hash12, Hash22, Hash33, ValueNoise, ValueNoise2D, GradientNoise2D, Voronoi2D, Fbm, Fbm2D, FbmWarped |
| `Shaders/Color.hlsl` | RGBtoHSV, HSVtoRGB, XYZtoLinearSRGB, CIE1931, LinearToGamma, GammaToLinear, Blackbody |
| `Shaders/Math.hlsl` | RotateAboutAxis, RotateX, RotateY, RotateZ, RemapRange |
| `Shaders/Optics.hlsl` | FresnelSchlick, ThinFilmOPD, ThinFilmReflectance, SpectralFilter |
| `Shaders/Lighting.hlsl` | DiffuseLambert, DiffuseWrapped, DiffuseOrenNayar, DistributionGGX, GeometrySmithGGX, FresnelSchlickRoughness, SpecularCookTorrance |
| `Shaders/SDF.hlsl` | SdSphere, SdBox, SdTorus, SdCapsule, SdPlane, Op* boolean/smooth/domain operators, Raymarch, SdfSceneNormal, SdfSoftShadow |
| `Shaders/NormalMap.hlsl` | DecodeNormalMap, DecodeNormalMapScaled, NormalFromHeight, NoiseNormal |
| `Shaders/UV.hlsl` | RotateUV, ScaleUV, ToPolar, FromPolar, Triplanar |
| `Shaders/Easing.hlsl` | SmootherStep, EaseInOutCubic, EaseOutElastic, EaseOutBounce, Gain, Pulse |
| `Shaders/SpaceTransforms.hlsl` | LinearEyeDepthFromRaw, LinearDepth01FromRaw, WorldPosFromDepth, Bayer4x4, DitherClip |

## Shader Graph

`ShaderGraph/Wrappers/` exposes the functions that have no built-in Shader Graph
equivalent as `_float` / `_half` forwarders for Custom Function nodes. Each one
is packaged as a Sub Graph under `ShaderGraph/Nodes/`. See
[ShaderGraph/README.md](ShaderGraph/README.md).

## Installation

Add to your Unity project via the Package Manager using the Git URL:

```
https://github.com/colesloow/unity_shader_lib.git
```

Or clone locally and add via `Add package from disk` pointing to the `package.json`.

## Usage

```hlsl
#include "Packages/com.coleslow.shaderlib/Shaders/Noise.hlsl"
#include "Packages/com.coleslow.shaderlib/Shaders/Optics.hlsl"
```

### Raymarching with SDF.hlsl

The raymarch helpers need your scene distance function. Include once for the
primitives, write the scene, then include again with the scene macro defined:

```hlsl
#include "Packages/com.coleslow.shaderlib/Shaders/SDF.hlsl"

float MyScene(float3 p) { return SdSphere(p, 1.0); }
#define COLESLOW_SDF_SCENE(p) MyScene(p)

#include "Packages/com.coleslow.shaderlib/Shaders/SDF.hlsl"
```

`SdfSceneNormal`, `Raymarch` and `SdfSoftShadow` are then available. The
primitives and operators do not require the macro.

## License

MIT
