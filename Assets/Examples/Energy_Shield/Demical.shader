Shader "aj7/URP/Demical"
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,1)
        _MainTex("Main Texture",2D)="white"{}

    }
    SubShader
    {
        Tags 
        {             
            "RenderType" = "Transparent"
            "Queue" = "Transparent" 
        }
        //LOD 100
        //透明物体加：
        ZWrite Off
        
        Blend One One
        Pass
        {
            Name "DemicalPass"
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
            half4 _Color;
            half _HighlightFade;
            CBUFFER_END

 
            TEXTURE2D(_MainTex);  
            SAMPLER(sampler_MainTex);  
            float4 _MainTex_ST;

            TEXTURE2D(_CameraDepthTexture); 
            SAMPLER(sampler_CameraDepthTexture);  


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
                float3 positionWS : TEXCOORD1;
                float3 positionVS : TEXCOORD2;
                float3 positionOS : TEXCOORD3;
            };

            //顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.positionVS=TransformWorldToView(o.positionWS);
                o.positionOS=v.positionOS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }
            half4 frag (Varyings i):SV_Target
            {
                half4 c;
                float2 screenUV = i.positionCS.xy / _ScreenParams.xy;

                
                half4 depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                 
                //片段对应深度图中的像素在观察空间下的z值
                half depthZ = LinearEyeDepth(depthMap, _ZBufferParams);

                float4 depthVS =1;
                depthVS.xy=i.positionVS.xy*depthZ/-i.positionVS.z;
                depthVS.z=depthZ;
                //构建深度图上的像素在世界空间下的坐标
                float3 depthWS =mul(unity_CameraToWorld,depthVS);
                float3 depthOS =mul(unity_WorldToObject,float4(depthWS,1));
                float2 uv =depthOS.xz+0.5;

                half4 mainTex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);

                c=mainTex*_Color;
                return c;

            }
            ENDHLSL
        }
    }
}