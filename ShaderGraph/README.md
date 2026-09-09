# Shader Graph wrappers

A thin layer that exposes the HLSL library as Shader Graph nodes. Nothing in
`Shaders/` is duplicated: the wrappers just forward calls, and each function
becomes one Sub Graph asset that shows up in the node search by name.

## Layout

```
ShaderGraph/
  Wrappers/   HLSL wrapper files, one per source module (versioned)
  Nodes/      .shadersubgraph assets, one per function (made in the editor)
  README.md   this file
```

Do not move `Wrappers/` after Sub Graphs reference it: a Custom Function node in
File mode stores the HLSL path, and every Sub Graph would lose its reference.

## Convention

- **Wrapper function**: `void <LibName>_float(<inputs>, out <T> Out)` plus a
  matching `_half` variant. Shader Graph picks `_float` or `_half` from the
  graph's precision setting; both must exist.
- **Return by `out` parameter**, never by `return` (Custom Function requirement).
  A function returning two values (e.g. `Voronoi2D`) gets two `out` ports.
- **Port names**: PascalCase, meaningful (`NdotH`, `Roughness`, `HalfExtents`).
- **Sub Graph asset name**: exactly `<LibName>` so it is found by that name.
- **Sub Graph category**: `Coleslow/<Domain>` (set in the Sub Graph's Blackboard
  or via the asset path `Nodes/<Domain>/<LibName>.shadersubgraph`).

## What is wrapped

Only functions with no built-in Shader Graph equivalent. Redundant ones
(`Remap`, `RotateAboutAxis`, RGB/HSV, Linear/Gamma, `Blackbody`, Fresnel,
normal unpack, UV rotate/scale/polar, triplanar, depth linearize, dither) are
left to the native nodes.

| Wrapper file | Functions |
|---|---|
| `NoiseSG.hlsl` | Hash12, Hash13, Hash22, Hash33, Fbm, Fbm2D, FbmWarped, Voronoi2D |
| `ColorSG.hlsl` | Lobe, CIE1931, XYZtoLinearSRGB, WavelengthToRGB |
| `OpticsSG.hlsl` | ThinFilmOPD, ThinFilmReflectance, SpectralFilter |
| `LightingSG.hlsl` | DiffuseLambert, DiffuseWrapped, DiffuseOrenNayar, DistributionGGX, GeometrySmithGGX, FresnelSchlickRoughness, SpecularCookTorrance |
| `NormalMapSG.hlsl` | NoiseNormal |
| `EasingSG.hlsl` | SmootherStep, EaseInOutCubic, EaseOutElastic, EaseOutBounce, Gain, Pulse |
| `SpaceTransformsSG.hlsl` | WorldPosFromDepth |
| `SDFSG.hlsl` | SdSphere, SdBox, SdTorus, SdCapsule, SdPlane, OpUnion, OpSubtract, OpIntersect, Smin, OpSmoothUnion, OpSmoothSubtract, OpSmoothIntersect |

`WavelengthToRGB` is a convenience combo not in the base library
(`saturate(XYZtoLinearSRGB(CIE1931(nm)))`).

## Adding a new node

1. Append a `_float` / `_half` pair to the matching `Wrappers/*SG.hlsl`:
   ```hlsl
   void MyFunction_float(float A, out float Out) { Out = MyFunction(A); }
   void MyFunction_half(half A, out half Out)    { Out = MyFunction(A); }
   ```
2. In the editor: create `Nodes/<Domain>/MyFunction.shadersubgraph`.
3. Inside it, add a **Custom Function** node, File mode, pointing at the wrapper
   file, `Name` = `MyFunction` (no suffix), and declare the ports to match the
   wrapper signature.
4. Add matching Sub Graph input/output properties and wire them through.
5. Commit the `.shadersubgraph` and its `.meta`.

Existing Sub Graphs are never touched.

## Not portable

- **SDF raymarcher** (`Raymarch`, `SdfSceneNormal`, `SdfSoftShadow`): the scene
  distance function must be HLSL, and a Custom Function node cannot call back
  into a graph. Stays code-only.
- **Struct returns** (`SdfHit`): split into separate `out` ports if ever needed.
