Shader "aj7/URP/Demical"
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,1)
        _MainTex("Main Texture",2D)="white"{}
        _DecalScale("Decal Scale", Float) = 1.0
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
        //Blend SrcAlpha OneMinusSrcAlpha
        Blend One One
        Pass
        {
            Name "DecalPass"
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
            half _DecalScale;
            CBUFFER_END

            #define smp _linear_clamp
            SAMPLER(smp);  

 
            TEXTURE2D(_MainTex);  
            //SAMPLER(sampler_MainTex);  
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
       
                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                 
                //片段对应深度图中的像素在观察空间下的z值
                half depthZ = LinearEyeDepth(depthMap, _ZBufferParams);

                float4 depthVS =1;
                depthVS.xy=i.positionVS.xy*depthZ/-i.positionVS.z;
                depthVS.z=depthZ;
                //构建深度图上的像素在世界空间下的坐标
                float3 depthWS =mul(unity_CameraToWorld,depthVS);
                float3 depthOS =mul(unity_WorldToObject,float4(depthWS,1));
                //若为面片则.xy，若为方块则.xz
                float2 uv =depthOS.xz/_DecalScale+0.5;

                half4 mainTex=SAMPLE_TEXTURE2D(_MainTex,smp,uv);

                c=mainTex*_Color;
                return c;

            }
            ENDHLSL
        }
    }

        //BuildIn
    SubShader
    {
        Tags 
        {             
            "RenderType" = "Transparent"
            "Queue" = "Transparent" 
        }
        ZWrite Off
        Blend One One
        GrabPass{"_GrabTex"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            half4 _Color;
            half _DecalScale;


            sampler2D _MainTex; float4 _MainTex_ST;
            sampler2D _CameraDepthTexture; float4 _CameraDepthTexture_ST;
            sampler2D _GrabTex; float4 _GrabTex_ST; 

            struct appdata
            {
                float2 uv:TEXCOORD0;
                float4 positionOS : POSITION;
            };

            struct v2f
            {
                float4 positionCS : SV_Position;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 positionVS : TEXCOORD2;
                float3 positionOS : TEXCOORD3;

            };
 
            v2f vert (appdata v)
            {
                v2f o;
                o.positionWS = mul(unity_ObjectToWorld, v.positionOS.xyz);
                o.positionCS = UnityObjectToClipPos(v.positionOS);
                o.positionOS=v.positionOS;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            { 
                half4 c;
                float2 screenUV = i.positionCS.xy / _ScreenParams.xy;
                half depthMap = tex2D(_CameraDepthTexture , screenUV);
                 
                //片段对应深度图中的像素在观察空间下的z值
                half depthZ = LinearEyeDepth(depthMap);

                float4 depthVS =1;
                depthVS.xy=i.positionVS.xy*depthZ/-i.positionVS.z;
                depthVS.z=depthZ;
                //构建深度图上的像素在世界空间下的坐标
                float3 depthWS =mul(unity_CameraToWorld,depthVS);
                float3 depthOS =mul(unity_WorldToObject,float4(depthWS,1));
                //若为面片则.xy，若为方块则.xz
                float2 uv =depthOS.xz/_DecalScale+0.5;

                half4 mainTex=tex2D(_MainTex,uv);

                c=mainTex*_Color;
                return c;

            }

            ENDCG

        }
    }
            Fallback "Diffuse"

}