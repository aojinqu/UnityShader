Shader "aj7/URP/Outline_1"
{
    Properties
    {
        [Header(Outline Settings)]
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0.001, 0.5)) = 0.05
        
        [Header(Body Settings)]
        _Color ("Body Base Color (Tint)", Color) = (1, 1, 1, 1) // 修正：主体颜色属性
        _MainTex ("Base Texture", 2D) = "white" {} // 修正：主体纹理属性
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
            Name "Pass"
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.0
            #pragma multi_compile_instancing

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _OutlineColor;    
            float _OutlineThickness;
            float4 _Color;
            float4 _MainTex_ST;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_Position;
                float2 uv : TEXCOORD0;
                float3 positionVS : TEXCOORD1;
                float4 color : COLOR;
            };
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float3 normal = normalize(v.normalOS);
                half3 objectViewDir = GetObjectSpaceNormalizeViewDir(v.positionOS);
                
                float factor = step(_OutlineThickness, dot(normal, objectViewDir));
                o.color=float4(1, 1, 1, 1) * factor;
                float3 positionWS = TransformObjectToWorld(v.positionOS);
                o.positionVS = TransformWorldToView(positionWS);
                o.positionCS = TransformObjectToHClip(v.positionOS);

                return o;
            }


            half4 frag(Varyings i):SV_Target
            {
                half4 c;
                c = _OutlineColor*i.color;  // 使用轮廓颜色
                return c;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Pass"
            Tags { "LightMode" = "UniversalForward" } 
            //这一句至关重要！！！！！！在URP中不是使用Forwardbase的
            //同时也得知了，在unity中出现紫色材质但没有报错，一般都是URP和buildin的配置问题
            //用于前向渲染路径，所有的灯光都在这一个pass中执行，包括GI、自发光、雾效.(在不需要光照的pass中，可以不写LightMode)
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.0
            #pragma multi_compile_instancing

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;           // 主体颜色 (用于着色)
            float4 _MainTex_ST;
            CBUFFER_END


            TEXTURE2D(_MainTex);    //纹理的定义，如果是编译到GLES2.0平台，则相当于sampler2D _MainTex;否则就相当于Texture2D _MainTex;
            SAMPLER(sampler_MainTex);  //采样器的定义，如果是编译到GLES2.0平台，默认相当于空，否则就相当于samplerState sampler_MainTex;

            //顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            //顶点着色器的输出
            struct Varyings
            {
                float4 positionCS : SV_Position;
                float2 uv : TEXCOORD0;
            };

            //顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float3 positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (Varyings i):SV_Target
            {
                //unity的unlit shader
                half4 c;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                c = mainTex * _Color;
                return c;
                
                //lit shader等后续讲了补上

                
            }
                
            ENDHLSL
        }
    }
    
}