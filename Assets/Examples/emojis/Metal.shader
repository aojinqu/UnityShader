Shader "Custom/Metallic_PBR"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _Metallic("Metallic", Range(0, 1)) = 1.0
        _Smoothness("Smoothness", Range(0, 1)) = 0.5
        [Toggle] _UseNormalMap("Use Normal Map", Float) = 0
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalScale("Normal Scale", Range(0, 2)) = 1.0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }
        LOD 300

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SCREEN
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_ON
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _Metallic;
                float _Smoothness;
                float _UseNormalMap;
                float _NormalScale;
                float4 _NormalMap_ST;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : NORMAL;
                float4 tangentWS : TANGENT;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float fogCoord : TEXCOORD2;
            };

            // Vertex Shader
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS.xyz, input.tangentOS.w);

                output.uv = TRANSFORM_TEX(input.uv, _NormalMap);

                output.fogCoord = ComputeFogFactor(output.positionCS.z);

                return output;
            }

            // Fragment Shader
            half4 frag(Varyings input) : SV_Target
            {
                // 计算世界空间法线
                float3 normalWS = SafeNormalize(input.normalWS);
                float3 normalTS = float3(0.0, 0.0, 1.0); // 默认切线空间法线

                // 根据 _UseNormalMap 属性决定是否使用法线贴图
                if (_UseNormalMap > 0.5)
                {
                    // 获取基础法线和切线（用于构建变换矩阵）
                    float3 baseNormalWS = SafeNormalize(input.normalWS);
                    float3 tangentWS = SafeNormalize(input.tangentWS.xyz);
                    float3 bitangentWS = SafeNormalize(cross(baseNormalWS, tangentWS) * input.tangentWS.w);
                    float3x3 tangentToWorld = float3x3(tangentWS, bitangentWS, baseNormalWS);
                    
                    // 采样法线贴图
                    normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv), _NormalScale);
                    
                    // 将切线空间法线转换到世界空间
                    normalWS = SafeNormalize(mul(normalTS, tangentToWorld));
                }

                // A. 设置 PBR 表面数据
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = _BaseColor.rgb;
                surfaceData.metallic = _Metallic;
                surfaceData.smoothness = _Smoothness;
                surfaceData.alpha = _BaseColor.a;
                surfaceData.normalTS = normalTS;
                surfaceData.occlusion = 1.0;
                surfaceData.emission = half3(0, 0, 0);
                surfaceData.clearCoatMask = 0.0;
                surfaceData.clearCoatSmoothness = 0.0;

                // B. 计算环境光照（GI）
                half3 bakedGI = SampleSH(normalWS);
                #ifdef LIGHTMAP_ON
                    bakedGI = SAMPLE_GI(input.uv, bakedGI, normalWS);
                #endif

                // C. 设置光照数据
                InputData inputData;
                inputData.positionWS = input.positionWS;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = SafeNormalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                inputData.fogCoord = input.fogCoord;
                inputData.vertexLighting = half3(0, 0, 0);
                inputData.bakedGI = bakedGI;
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = half4(1, 1, 1, 1);

                // D. 执行 PBR 光照计算
                half4 finalColor = UniversalFragmentPBR(inputData, surfaceData);

                // E. 应用雾效
                finalColor.rgb = MixFog(finalColor.rgb, input.fogCoord);
                return finalColor;
                //return _BaseColor;

            }
            ENDHLSL
        }
    }

    //FallBack "Universal Render Pipeline/Lit"
}
