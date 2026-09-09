// Compile-coverage test for the Shader Graph wrapper layer (ShaderGraph/Wrappers).
// Includes every wrapper file and calls every _float wrapper so a bad lib name,
// signature mismatch or include path fails the build. Not a visual test.
// Drop in a URP project's Assets, assign to a material, check the Console.
Shader "Coleslow/Tests/ShaderGraphWrappersTest"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "Packages/com.coleslow.shaderlib/ShaderGraph/Wrappers/NoiseSG.hlsl"
            #include "Packages/com.coleslow.shaderlib/ShaderGraph/Wrappers/ColorSG.hlsl"
            #include "Packages/com.coleslow.shaderlib/ShaderGraph/Wrappers/OpticsSG.hlsl"
            #include "Packages/com.coleslow.shaderlib/ShaderGraph/Wrappers/LightingSG.hlsl"
            #include "Packages/com.coleslow.shaderlib/ShaderGraph/Wrappers/NormalMapSG.hlsl"
            #include "Packages/com.coleslow.shaderlib/ShaderGraph/Wrappers/EasingSG.hlsl"
            #include "Packages/com.coleslow.shaderlib/ShaderGraph/Wrappers/SpaceTransformsSG.hlsl"
            #include "Packages/com.coleslow.shaderlib/ShaderGraph/Wrappers/SDFSG.hlsl"

            struct Attributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings   { float4 positionCS : SV_POSITION; float2 uv : TEXCOORD0; };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;
                float3 p = float3(uv, uv.x);
                float3 n = normalize(float3(uv, 1.0));
                float3 l = normalize(float3(0.3, 0.8, 0.2));
                float acc = 0.0;
                float f1; float f2; float o1; float3 o3;

                // Noise
                Hash12_float(uv, o1); acc += o1;
                Hash13_float(p, o1); acc += o1;
                Hash22_float(uv, o3.xy); acc += o3.x;
                Hash33_float(p, o3); acc += o3.x;
                Fbm_float(p, o1); acc += o1;
                Fbm2D_float(uv, o1); acc += o1;
                FbmWarped_float(p, 0.5, o1); acc += o1;
                Voronoi2D_float(uv * 8.0, 1.0, f1, f2); acc += f1 + f2;

                // Color
                Lobe_float(550.0, 560.0, 40.0, 40.0, o1); acc += o1;
                CIE1931_float(uv.x * 360.0 + 380.0, o3); acc += o3.y;
                XYZtoLinearSRGB_float(o3, o3); acc += o3.z;
                WavelengthToRGB_float(uv.x * 360.0 + 380.0, o3); acc += o3.x;

                // Optics
                float opd; ThinFilmOPD_float(dot(n, l), 1.4, 320.0, opd); acc += opd;
                ThinFilmReflectance_float(opd, 550.0, o1); acc += o1;
                SpectralFilter_float(opd, o3); acc += o3.x;

                // Lighting
                DiffuseLambert_float(n, l, o1); acc += o1;
                DiffuseWrapped_float(n, l, 0.5, o1); acc += o1;
                DiffuseOrenNayar_float(n, l, n, 0.6, o1); acc += o1;
                DistributionGGX_float(saturate(dot(n, l)), 0.4, o1); acc += o1;
                GeometrySmithGGX_float(0.7, 0.6, 0.4, o1); acc += o1;
                FresnelSchlickRoughness_float(0.5, 0.04, 0.4, o3); acc += o3.x;
                SpecularCookTorrance_float(n, n, l, 0.04, 0.4, o3); acc += o3.x;

                // NormalMap
                NoiseNormal_float(uv * 16.0, 0.01, 1.0, o3); acc += o3.x;

                // Easing
                SmootherStep_float(uv.x, o1); acc += o1;
                EaseInOutCubic_float(uv.x, o1); acc += o1;
                EaseOutElastic_float(uv.x, o1); acc += o1;
                EaseOutBounce_float(uv.x, o1); acc += o1;
                Gain_float(uv.x, 2.0, o1); acc += o1;
                Pulse_float(0.2, 0.8, uv.x, o1); acc += o1;

                // SpaceTransforms
                WorldPosFromDepth_float(uv, 0.5, UNITY_MATRIX_I_VP, o3); acc += o3.x;

                // SDF
                float da; float db; float dc;
                SdSphere_float(p, 1.0, da); acc += da;
                SdBox_float(p, float3(0.5, 0.5, 0.5), db); acc += db;
                SdTorus_float(p, 1.0, 0.25, dc); acc += dc;
                SdCapsule_float(p, float3(0, -1, 0), float3(0, 1, 0), 0.3, o1); acc += o1;
                SdPlane_float(p, float3(0, 1, 0), o1); acc += o1;
                OpUnion_float(da, db, o1); acc += o1;
                OpSubtract_float(da, db, o1); acc += o1;
                OpIntersect_float(da, db, o1); acc += o1;
                Smin_float(da, db, 0.1, o1); acc += o1;
                OpSmoothUnion_float(da, db, 0.1, o1); acc += o1;
                OpSmoothSubtract_float(da, db, 0.1, o1); acc += o1;
                OpSmoothIntersect_float(da, db, 0.1, o1); acc += o1;

                // half sanity check (representative)
                half h; Hash12_half((half2)uv, h); acc += h;
                half3 h3; SpecularCookTorrance_half((half3)n, (half3)n, (half3)l, (half3)0.04, (half)0.4, h3); acc += h3.x;

                return float4(saturate(acc * 1e-3 + 0.5).xxx, 1.0);
            }
            ENDHLSL
        }
    }
}
