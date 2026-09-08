// Compile-coverage test for com.coleslow.shaderlib.
// Includes every module and references every public function so nothing is
// dead-code stripped. Not a visual test: it just has to compile without errors.
// Drop this in a URP project's Assets, assign it to a material, and check the
// Console (and the shader Inspector's "Compile and show code").
Shader "Coleslow/Tests/AllModulesTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "gray" {}
        _NormalTex ("Normal", 2D) = "bump" {}
    }
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

            #include "Packages/com.coleslow.shaderlib/Shaders/Math.hlsl"
            #include "Packages/com.coleslow.shaderlib/Shaders/Noise.hlsl"
            #include "Packages/com.coleslow.shaderlib/Shaders/Color.hlsl"
            #include "Packages/com.coleslow.shaderlib/Shaders/Optics.hlsl"
            #include "Packages/com.coleslow.shaderlib/Shaders/Lighting.hlsl"
            #include "Packages/com.coleslow.shaderlib/Shaders/NormalMap.hlsl"
            #include "Packages/com.coleslow.shaderlib/Shaders/UV.hlsl"
            #include "Packages/com.coleslow.shaderlib/Shaders/Easing.hlsl"
            #include "Packages/com.coleslow.shaderlib/Shaders/SpaceTransforms.hlsl"
            #include "Packages/com.coleslow.shaderlib/Shaders/SDF.hlsl"

            // Raymarch layer: scene function then a second include.
            float TestScene(float3 p)
            {
                float a = SdSphere(p, 1.0);
                float b = SdBox(p - float3(1, 0, 0), float3(0.5, 0.5, 0.5));
                float c = SdTorus(p, 1.0, 0.25);
                float d = SdCapsule(p, float3(0, -1, 0), float3(0, 1, 0), 0.3);
                float e = SdPlane(p - float3(0, -1, 0), float3(0, 1, 0));
                float s = OpSmoothUnion(OpUnion(a, b), OpSmoothSubtract(c, d, 0.1), 0.2);
                s = OpIntersect(s, e + 10.0);
                s = OpSmoothIntersect(s, a + 5.0, 0.1);
                p = OpRepeat(p, float3(8, 8, 8));
                p = OpTwist(p, 0.1);
                p = OpBend(p, 0.05);
                return min(s, Smin(a, b, 0.1) + length(p) * 0.0);
            }
            #define COLESLOW_SDF_SCENE(p) TestScene(p)
            #include "Packages/com.coleslow.shaderlib/Shaders/SDF.hlsl"

            TEXTURE2D(_MainTex);   SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);

            struct Attributes { float4 positionOS : POSITION; float3 normalOS : NORMAL; float2 uv : TEXCOORD0; };
            struct Varyings   { float4 positionCS : SV_POSITION; float3 positionWS : TEXCOORD0; float3 normalWS : TEXCOORD1; float2 uv : TEXCOORD2; };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs pos = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = pos.positionCS;
                OUT.positionWS = pos.positionWS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float3 acc = 0.0;
                float2 uv = IN.uv;
                float3 n = normalize(IN.normalWS);
                float3 v = normalize(GetWorldSpaceViewDir(IN.positionWS));
                float3 l = normalize(float3(0.3, 0.8, 0.2));

                // Math
                acc += RotateAboutAxis(v, n, 0.5);
                acc += RotateX(v, 0.1) + RotateY(v, 0.1) + RotateZ(v, 0.1);
                acc += RemapRange(uv.x, 0.0, 1.0, -1.0, 1.0);

                // Noise
                acc += Hash13(IN.positionWS) + Hash12(uv);
                acc += float3(Hash22(uv), 0.0) + Hash33(IN.positionWS);
                acc += ValueNoise(IN.positionWS) + ValueNoise2D(uv * 8.0);
                acc += GradientNoise2D(uv * 8.0);
                acc += float3(Voronoi2D(uv * 8.0, 1.0), 0.0);
                acc += Fbm(IN.positionWS) + Fbm2D(uv * 4.0) + FbmWarped(IN.positionWS, 0.5);

                // Color
                float3 hsv = RGBtoHSV(saturate(acc));
                acc += HSVtoRGB(hsv);
                acc += XYZtoLinearSRGB(CIE1931(550.0)) * Lobe(550.0, 560.0, 40.0, 40.0);
                acc += LinearToGamma(saturate(acc)) + GammaToLinear(saturate(acc));
                acc += Blackbody(6500.0);

                // Optics
                float opd = ThinFilmOPD(dot(n, v), 1.4, 320.0);
                acc += FresnelSchlick(saturate(dot(n, v)), 0.04);
                acc += ThinFilmReflectance(opd, 550.0);
                acc += SpectralFilter(opd);

                // Lighting
                acc += DiffuseLambert(n, l) + DiffuseWrapped(n, l, 0.5);
                acc += DiffuseOrenNayar(n, l, v, 0.6);
                acc += D_GGX(saturate(dot(n, normalize(v + l))), 0.4);
                acc += G_SmithSchlick(saturate(dot(n, v)), saturate(dot(n, l)), 0.4);
                acc += FresnelSchlickRoughness(saturate(dot(n, v)), 0.04, 0.4);
                acc += SpecularCookTorrance(n, v, l, 0.04, 0.4);

                // NormalMap
                float4 nSample = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, uv);
                acc += DecodeNormalMap(nSample) + DecodeNormalMapScaled(nSample, 2.0);
                acc += NormalFromHeight(uv, 0.5, 0.6, 0.4, 0.01, 1.0);
                acc += NoiseNormal(uv * 16.0, 0.01, 1.0);

                // UV
                acc.xy += RotateUV(uv, 0.5, 0.5) + ScaleUV(uv, float2(2, 2), 0.5);
                float2 polar = ToPolar(uv, 0.5);
                acc.xy += polar + FromPolar(polar, 0.5);
                acc += Triplanar(_MainTex, sampler_MainTex, IN.positionWS, n, 0.5, 4.0).rgb;

                // Easing
                acc += SmootherStep(uv.x) + EaseInOutCubic(uv.x) + EaseOutElastic(uv.x);
                acc += EaseOutBounce(uv.x) + Gain(uv.x, 2.0) + Pulse(0.2, 0.8, uv.x);

                // SpaceTransforms
                float rawDepth = IN.positionCS.z / IN.positionCS.w;
                acc += LinearEyeDepthFromRaw(rawDepth, 0.1, 1000.0);
                acc += LinearDepth01FromRaw(rawDepth, 0.1, 1000.0);
                acc += WorldPosFromDepth(uv, rawDepth, UNITY_MATRIX_I_VP);
                acc += Bayer4x4(IN.positionCS.xy);
                acc += DitherClip(0.5, IN.positionCS.xy);

                // SDF raymarch layer
                SdfHit hit = Raymarch(IN.positionWS + float3(0, 0, -5), float3(0, 0, 1), 64, 0.001, 50.0);
                acc += hit.hit ? hit.pos : float3(hit.t, hit.steps, 0.0);
                acc += SdfSceneNormal(IN.positionWS);
                acc += SdfSoftShadow(IN.positionWS + n * 0.01, l, 10.0, 16.0);

                return float4(saturate(acc * 1e-4 + 0.5), 1.0);
            }
            ENDHLSL
        }
    }
}
