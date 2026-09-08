# unity_shader_lib

A modular HLSL shader library for Unity.

## Modules

| File | Contents |
|---|---|
| `Shaders/Noise.hlsl` | Hash13, ValueNoise, Fbm, FbmWarped |
| `Shaders/Color.hlsl` | RGBtoHSV, HSVtoRGB, XYZtoLinearSRGB, CIE1931 |
| `Shaders/Math.hlsl` | RotateAboutAxis, RotateY |
| `Shaders/Optics.hlsl` | FresnelSchlick, ThinFilmOPD, ThinFilmReflectance, SpectralFilter |

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
