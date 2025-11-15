Shader "Custom/Gemstone"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 0.8, 0.2, 1)
        _Transparency("Transparency", Range(0, 1)) = 0.3
        _RefractionIndex("Refraction Index", Range(1, 2.5)) = 1.5
        _Smoothness("Smoothness", Range(0, 1)) = 0.95
        _Metallic("Metallic", Range(0, 1)) = 0.0
        _DarkIntensity("Dark Intensity", Range(0, 2)) = 1.0
        _HighlightIntensity("Highlight Intensity", Range(0, 5)) = 3.0
        _FresnelPower("Fresnel Power", Range(0.1, 5)) = 2.0
        _FresnelIntensity("Fresnel Intensity", Range(0, 2)) = 1.0
        [Toggle] _UseNormalMap("Use Normal Map", Float) = 0
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalScale("Normal Scale", Range(0, 2)) = 1.0
    }

    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalRenderPipeline" 
            "RenderType" = "Transparent" 
            "Queue" = "Transparent"
        }
        LOD 300

        // 第一个Pass：渲染背面（用于折射效果）
        Pass
        {
            Name "BackFace"
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Front
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _Transparency;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float fogCoord : TEXCOORD1;
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, float4(0,0,0,0));
                output.normalWS = normalInput.normalWS;
                output.fogCoord = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 col = _BaseColor;
                col.a *= _Transparency * 0.5; // 背面更透明
                col.rgb = MixFog(col.rgb, input.fogCoord);
                return col;
            }
            ENDHLSL
        }

        // 第二个Pass：渲染正面（主要效果）
        Pass
        {
            Name "FrontFace"
            Tags { "LightMode" = "UniversalForward" }

            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _Transparency;
                float _RefractionIndex;
                float _Smoothness;
                float _Metallic;
                float _DarkIntensity;
                float _HighlightIntensity;
                float _FresnelPower;
                float _FresnelIntensity;
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
                float3 viewDirWS : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float fogCoord : TEXCOORD4;
            };

            // 计算菲涅尔效果
            float CalculateFresnel(float3 viewDir, float3 normal, float power)
            {
                float fresnel = pow(1.0 - saturate(dot(viewDir, normal)), power);
                return fresnel;
            }

            // 计算折射偏移
            float2 CalculateRefraction(float3 viewDir, float3 normal, float refractionIndex)
            {
                float3 refractedDir = refract(-viewDir, normal, 1.0 / refractionIndex);
                float2 offset = refractedDir.xy * 0.1; // 调整折射强度
                return offset;
            }

            // 计算基于法线的高光（模拟切割面高光）
            float CalculateFacetHighlight(float3 normal, float3 viewDir, float3 lightDir)
            {
                // 计算反射方向
                float3 reflectDir = reflect(-lightDir, normal);
                float specular = pow(saturate(dot(viewDir, reflectDir)), 64.0);
                
                // 基于法线变化增强高光（模拟切割面）
                float normalVariation = length(fwidth(normal)) * 10.0;
                specular *= (1.0 + normalVariation * 2.0);
                
                return specular;
            }

            // 计算暗面（基于法线与视角的关系）
            float CalculateDarkSide(float3 normal, float3 viewDir)
            {
                // 当法线背离视角时，形成暗面
                float facing = dot(normal, viewDir);
                float darkSide = saturate(-facing);
                return darkSide;
            }

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.screenPos = ComputeScreenPos(output.positionCS);

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS.xyz, input.tangentOS.w);

                output.uv = TRANSFORM_TEX(input.uv, _NormalMap);
                output.viewDirWS = SafeNormalize(_WorldSpaceCameraPos.xyz - output.positionWS);
                output.fogCoord = ComputeFogFactor(output.positionCS.z);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 计算世界空间法线
                float3 normalWS = SafeNormalize(input.normalWS);
                
                // 应用法线贴图（如果启用）
                if (_UseNormalMap > 0.5)
                {
                    float3 tangentWS = SafeNormalize(input.tangentWS.xyz);
                    float3 bitangentWS = SafeNormalize(cross(normalWS, tangentWS) * input.tangentWS.w);
                    float3x3 tangentToWorld = float3x3(tangentWS, bitangentWS, normalWS);
                    
                    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv), _NormalScale);
                    normalWS = SafeNormalize(mul(normalTS, tangentToWorld));
                }

                float3 viewDir = SafeNormalize(input.viewDirWS);
                float3 lightDir = SafeNormalize(_MainLightPosition.xyz);
                
                // 计算折射
                float2 refractionOffset = CalculateRefraction(viewDir, normalWS, _RefractionIndex);
                float2 screenUV = (input.screenPos.xy / input.screenPos.w) + refractionOffset;
                
                // 采样背景（用于折射效果）
                float depth = SampleSceneDepth(screenUV);
                float3 refractedColor = float3(0.1, 0.1, 0.15); // 默认背景色，可以改为采样场景颜色

                // 计算暗面
                float darkSide = CalculateDarkSide(normalWS, viewDir);
                float3 darkColor = _BaseColor.rgb * (1.0 - darkSide * _DarkIntensity * 0.5);

                // 计算高光
                float highlight = CalculateFacetHighlight(normalWS, viewDir, lightDir);
                highlight = pow(highlight, 1.0 / (1.0 - _Smoothness * 0.9));
                highlight *= _HighlightIntensity;

                // 计算菲涅尔效果（边缘高光）
                float fresnel = CalculateFresnel(viewDir, normalWS, _FresnelPower);
                fresnel *= _FresnelIntensity;

                // 计算主光源反射
                float NdotL = saturate(dot(normalWS, lightDir));
                float3 lightColor = _MainLightColor.rgb * NdotL;

                // 组合所有效果
                float3 finalColor = darkColor;
                
                // 添加折射效果（混合背景色）
                finalColor = lerp(finalColor, refractedColor, _Transparency * 0.3);
                
                // 添加高光
                finalColor += highlight * _MainLightColor.rgb;
                
                // 添加菲涅尔边缘高光
                finalColor += fresnel * _MainLightColor.rgb * 0.5;
                
                // 添加基础光照
                finalColor += lightColor * _BaseColor.rgb * 0.5;

                // 环境光
                half3 bakedGI = SampleSH(normalWS);
                #ifdef LIGHTMAP_ON
                    bakedGI = SAMPLE_GI(input.uv, bakedGI, normalWS);
                #endif
                finalColor += bakedGI * _BaseColor.rgb * 0.3;

                // 计算透明度
                float alpha = _BaseColor.a * _Transparency;
                // 边缘更透明
                alpha *= (1.0 - fresnel * 0.3);

                half4 final = half4(finalColor, alpha);

                // 应用雾效
                final.rgb = MixFog(final.rgb, input.fogCoord);

                return final;
            }
            ENDHLSL
        }
    }

    //FallBack "Universal Render Pipeline/Unlit"
}

