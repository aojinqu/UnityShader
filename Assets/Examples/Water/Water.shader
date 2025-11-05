Shader "aj7/URP/Water"
{
    Properties
    {
        _WaterColor01("Color01",Color)=(1,1,1,1)
        _WaterColor02("Color02",Color)=(1,1,1,1)
        _MainTex("Main Texture",2D)="white"{}

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
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _WaterColor01;
            half4 _WaterColor02;
            CBUFFER_END

            TEXTURE2D(_CameraDepthTexture); 
            SAMPLER(sampler_CameraDepthTexture);  

            TEXTURE2D(_MainTex);     
            SAMPLER(sampler_MainTex);  
            float4 _MainTex_ST;


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
                float3 positionVS:TEXCOORD1;
            };

            //顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                float3 positionWS = TransformObjectToWorld(v.positionOS);
                o.positionVS=TransformWorldToView(positionWS);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;
                return o;
            }
            half4 frag (Varyings i):SV_Target
            {
                //屏幕空间下的UV坐标
                float2 screenUV = i.positionCS.xy / _ScreenParams.xy;

                //水的深度
                half depthTex=SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,screenUV);

                //水体对应深度图中的像素在观察空间下的z值
                half depthScene = Linear01Depth(depthTex, _ZBufferParams);
                half depthWater =depthScene+i.positionVS.z;
                return depthWater;

                // half4 c;
                // half4 mainTex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                // c=mainTex*_WaterColor01;
                // return c;
            }
            ENDHLSL
        }
    }
    
}