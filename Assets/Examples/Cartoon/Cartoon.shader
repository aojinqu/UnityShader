Shader "aj7/CartoonURP"
{
    Properties
    {
        [MainTexture]_BaseMap("Base Map", 2D) = "white" {}
        [MainColor]_BaseColor("Base Color", Color) = (1,1,1,1)

        [Toggle(_NORMALMAP)]_UseNormalMap("Use Normal Map", Float) = 0
        [Normal]_BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", Range(0,2)) = 1

        _ShadowTint("Shadow Tint (Multiply)", Color) = (0.35, 0.55, 1.0, 1)
        _RampMin("Ramp From Min", Range(0,1)) = 0.70
        _RampMax("Ramp From Max", Range(0,1)) = 0.72
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Material features
            #pragma shader_feature_local _NORMALMAP

            // URP lighting/shadow variants
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _ShadowTint;
                float _RampMin;
                float _RampMax;
                float _BumpScale;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                half4 tangentWS    : TEXCOORD4; // xyz=tangent, w=handedness
                float3 positionWS  : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                float3 tWS = TransformObjectToWorldDir(IN.tangentOS.xyz);
                OUT.tangentWS = half4(tWS, IN.tangentOS.w * GetOddNegativeScale());
                OUT.uv          = IN.uv;
                OUT.shadowCoord = TransformWorldToShadowCoord(OUT.positionWS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 baseSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * (half4)_BaseColor;

                // Main light term (includes shadows + distance attenuation)
                Light mainLight = GetMainLight(IN.shadowCoord);
                half3 N = normalize((half3)IN.normalWS);

                #if defined(_NORMALMAP)
                    // Tangent-space normal -> world-space normal
                    half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, IN.uv), (half)_BumpScale);
                    half3 T = normalize((half3)IN.tangentWS.xyz);
                    half3 B = normalize(cross(N, T) * (half)IN.tangentWS.w);
                    N = normalize(T * normalTS.x + B * normalTS.y + N * normalTS.z);
                #endif
                half3 L = normalize((half3)mainLight.direction);
                half ndotl = saturate(dot(N, L));

                half lightTerm = ndotl * mainLight.shadowAttenuation * mainLight.distanceAttenuation;

                // Blender 的 Map Range(fromMin=0.70, fromMax=0.72, to 0..1) 等价于 smoothstep
                half t = smoothstep((half)_RampMin, (half)_RampMax, lightTerm);

                // A=阴影色(贴图 * 蓝色tint)，B=原贴图；系数t在窄区间内快速过渡
                half3 shadowCol = baseSample.rgb * (half3)_ShadowTint.rgb;
                half3 litCol    = baseSample.rgb;
                half3 finalCol  = lerp(shadowCol, litCol, t);

                return half4(finalCol, baseSample.a);
            }
            ENDHLSL
        }

        /*
        // 让该材质“投下阴影”的关键 Pass（写入 ShadowMap）
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // URP shadow caster variants (directional / punctual)
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // URP 14 的 Shadows.hlsl 依赖 Core 包里的 LerpWhiteTo（定义在 CommonMaterial.hlsl）
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            Varyings ShadowPassVertex(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS   = TransformObjectToWorldNormal(IN.normalOS);

                // URP 会为 ShadowCaster Pass 提供 _LightDirection（平行光）
                // 以及在点光/聚光投影时需要的 _LightPosition
                float3 lightDirWS;
                #if defined(_CASTING_PUNCTUAL_LIGHT_SHADOW)
                    lightDirWS = normalize(_LightPosition.xyz - positionWS);
                #else
                    lightDirWS = _LightDirection;
                #endif

                float4 posHCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirWS));
                #if UNITY_REVERSED_Z
                    posHCS.z = min(posHCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    posHCS.z = max(posHCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                OUT.positionHCS = posHCS;
                return OUT;
            }

            half4 ShadowPassFragment(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        // 可选但推荐：深度预处理/深度纹理（部分后处理/特效依赖）
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };

            Varyings DepthOnlyVertex(Attributes IN)
            {
                Varyings OUT;
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                return OUT;
            }

            half4 DepthOnlyFragment(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
        */ 
    }
}