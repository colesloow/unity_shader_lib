# unity_shader_lib

A modular HLSL shader library for Unity.

## Modules

| File | Contents |
|---|---|
| `Shaders/Noise.hlsl` | Hash13, ValueNoise, Fbm, FbmWarped, Hash12, ValueNoise2D, Fbm2D |
| `Shaders/Color.hlsl` | RGBtoHSV, HSVtoRGB, XYZtoLinearSRGB, CIE1931, LinearToGamma, GammaToLinear, Blackbody |
| `Shaders/Math.hlsl` | RotateAboutAxis, RotateX, RotateY, RotateZ, Remap |
| `Shaders/Optics.hlsl` | FresnelSchlick, ThinFilmOPD, ThinFilmReflectance, SpectralFilter |
| `Shaders/SDF.hlsl` | SdSphere, SdBox, SdTorus, SdCapsule |
| `Shaders/NormalMap.hlsl` | UnpackNormal, UnpackNormalScaled, NormalFromHeight, NoiseNormal |

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

## License

MIT
