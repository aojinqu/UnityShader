Shader "Custom/ForceFieldHexagon"
{
    Properties
    {
        _MainColor("Main Color", Color) = (0.2, 0.6, 1.0, 0.8)
        _HexColor("Hex Color", Color) = (0.8, 0.9, 1.0, 1.0)
        _GridDensity("Grid Density", Float) = 10
        _LineWidth("Line Width", Range(0.01, 0.2)) = 0.05
        _GlowPower("Glow Power", Float) = 2
        _PulseSpeed("Pulse Speed", Float) = 1
        _FresnelPower("Fresnel Power", Range(0, 10)) = 3
        _FresnelIntensity("Fresnel Intensity", Float) = 2
    }
    
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }
        
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Back
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 viewDirWS : TEXCOORD3;
                float fresnel : TEXCOORD4;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainColor;
                float4 _HexColor;
                float _GridDensity;
                float _LineWidth;
                float _GlowPower;
                float _PulseSpeed;
                float _FresnelPower;
                float _FresnelIntensity;
            CBUFFER_END
            
            float HexDistance(float2 p)
            {
                p = abs(p);
                return max(p.x * 0.866025 + p.y * 0.5, p.y);
            }
            
            float HexGrid(float2 uv, float scale)
            {
                uv *= scale;
                
                float2 coord = float2(
                    uv.x * 2.0 * 1.15470054,
                    uv.y + uv.x * 0.5
                );
                
                float2 cell = floor(coord);
                float2 localUV = frac(coord) - 0.5;
                
                float dist = HexDistance(localUV);
                return dist;
            }
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS);
                
                OUT.positionHCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;
                OUT.normalWS = normalInputs.normalWS;
                OUT.uv = IN.uv;
                
                OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(positionInputs.positionWS);
                float NdotV = 1.0 - saturate(dot(normalInputs.normalWS, OUT.viewDirWS));
                OUT.fresnel = pow(NdotV, _FresnelPower) * _FresnelIntensity;
                
                return OUT;
            }
            
            half4 frag(Varyings IN) : SV_Target
            {
                float hexGrid = HexGrid(IN.uv, _GridDensity);
                float hexLine = smoothstep(_LineWidth, _LineWidth - 0.01, hexGrid);
                
                float pulse = (sin(_Time.y * _PulseSpeed) + 1.0) * 0.5;
                float animatedHexLine = hexLine * (0.7 + 0.3 * pulse);
                
                half3 baseColor = _MainColor.rgb;
                half3 hexColor = _HexColor.rgb;
                
                half3 finalColor = lerp(baseColor, hexColor, animatedHexLine);
                
                float glow = pow(animatedHexLine, _GlowPower);
                finalColor += hexColor * glow;
                
                finalColor *= (1.0 + IN.fresnel);
                float finalAlpha = _MainColor.a * (0.3 + 0.7 * IN.fresnel);
                
                return half4(finalColor, finalAlpha);
            }
            ENDHLSL
        }
    }
}