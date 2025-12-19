Shader "aj7/URP/WaterDepth"
{
    Properties
    {
        _SurfaceColor("Surface Color (Near Surface = Darker)", Color) = (0.02, 0.18, 0.35, 0.85)
        _DeepColor("Deep Color (Deeper = Lighter)", Color) = (0.35, 0.65, 0.85, 0.85)
        _DepthMax("Depth Max (World Units)", Float) = 5
        _DebugMode("Debug (0=Off,1=RawDepth,2=EyeDepth,3=WaterDepth)", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "WaterDepth"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _SurfaceColor;
                half4 _DeepColor;
                half  _DepthMax;
                half  _DebugMode;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_Position;
                float3 positionVS : TEXCOORD0;
                float4 screenPos  : TEXCOORD1;
            };

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS);
                o.positionCS = vertexInput.positionCS;
                o.positionVS = TransformWorldToView(vertexInput.positionWS);
                o.screenPos = ComputeScreenPos(o.positionCS);

                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                // 标准屏幕UV（兼容 RenderScale / 平台差异）
                float2 screenUV = i.screenPos.xy / i.screenPos.w;

                // 采样场景深度（0~1 的 raw depth）
                half rawDepth01 = SampleSceneDepth(screenUV);

                // 转眼空间线性深度（单位与世界单位一致，受 near/far 影响）
                half sceneEyeDepth = LinearEyeDepth(rawDepth01, _ZBufferParams);

                // 水深 = 场景像素深度 - 水面像素深度
                // Unity 观察空间相机朝 -Z，水面 i.positionVS.z 通常为负
                half waterDepth = sceneEyeDepth + i.positionVS.z;
                waterDepth = max(0, waterDepth); // 只保留水面下方

                // 调试：确认 Game 视图是否拿到深度纹理
                if (_DebugMode > 0.5h && _DebugMode < 1.5h) return half4(rawDepth01.xxx, 1);
                if (_DebugMode > 1.5h && _DebugMode < 2.5h) return half4(frac(sceneEyeDepth).xxx, 1);
                if (_DebugMode > 2.5h && _DebugMode < 3.5h) return half4(frac(waterDepth).xxx, 1);

                // 需求：越靠近水面颜色越深；越往下越浅
                half t = saturate(waterDepth / max(0.0001h, _DepthMax)); // 0=贴近水面，1=更深
                return lerp(_SurfaceColor, _DeepColor, t);
            }
            ENDHLSL
        }
    }
}


