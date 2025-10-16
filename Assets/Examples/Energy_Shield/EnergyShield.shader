Shader "aj7/URP/EnergyShield"
{
    Properties
    {
        _MainTex("Main Texture",2D)="white"{}
        _HighlightColor("Highlight Color",Color)=(1,1,1,1)
        _HighlightFade("HighlightFade",float)=1
        _FresnelColor("Fresnel Color",Color)=(1,1,1,1)
        _FresnelPower("FresnelPower",Range(1,15))=5

        _Tiling("Tilling",float)=5
        _Distort("Distort",Range(0,1))=0.048

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        //LOD 100
        //透明物体加：
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {

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
            half4 _HighlightColor;
            half _HighlightFade;
            half _FresnelPower;
            half4 _FresnelColor;
            half _Tiling;
            float4 _MainTex_ST;
            float _Distort;
            CBUFFER_END


            //#define smp sampler_MainTex
            //#define smp _linear_clampU_mirror 

            TEXTURE2D(_MainTex);    //纹理的定义，如果是编译到GLES2.0平台，则相当于sampler2D _MainTex;否则就相当于Texture2D _MainTex;
            //SAMPLER(smp);
            SAMPLER(sampler_MainTex);  //采样器的定义，如果是编译到GLES2.0平台，默认相当于空，否则就相当于samplerState sampler_MainTex;

            TEXTURE2D(_CameraDepthTexture); 
            SAMPLER(sampler_CameraDepthTexture);  

            TEXTURE2D(_CameraOpaqueTexture); 
            SAMPLER(sampler_CameraOpaqueTexture);             


            //顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            //顶点着色器的输出
            struct Varyings
            {
                float4 positionCS : SV_Position;
                float4 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 positionVS : TEXCOORD2;
                half3 normalWS : TEXCOORD3;
                half3 viewWS : TEXCOORD4;
            };

            //顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.positionVS=TransformWorldToView(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS = _WorldSpaceCameraPos- o.positionWS;
                o.uv.xy=v.uv;
                o.uv.zw = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }
            half4 frag (Varyings i):SV_Target
            {
                half4 c;
                float2 screenUV = i.positionCS.xy / _ScreenParams.xy;

                half4 mainTex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.zw+float2(0,_Time.y));
                //half4 mainTex01=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.zw+float2(0,_Time.y));

                half4 depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                //片段对应深度图中的像素在观察空间下的z值
                half depth = LinearEyeDepth(depthMap, _ZBufferParams);
                half4 hightLight= depth + i.positionVS.z; //用+是因为左手坐标系下VS的z是负的，我们又需要作差来取得他们之间的差值
                hightLight*=_HighlightFade;
                hightLight=1-hightLight;
                hightLight*=_HighlightColor;
                hightLight =saturate(hightLight);

                //菲涅尔外发光要记住计算NV 和点乘和次数幂
                half3 N = i.normalWS;
                half3 V = i.viewWS;
                half NdotV=1-saturate(dot(N,V));
                half4 fresnel =pow(abs(NdotV),_FresnelPower);
                fresnel*=_FresnelColor;

                //整合菲涅尔和边缘发光效果
                c=hightLight+fresnel;
                c=c+mainTex*0.02;

                //流光动画
                float2 distortUV=lerp(screenUV,mainTex.rr,_Distort);
                half4 opaqueMap = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, distortUV);
                
                half4 distort =half4(opaqueMap.rgb,1);
                half mask=frac(i.uv.y*_Tiling+_Time.y);
                distort*=mask;
                c+=distort;
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
        LOD 600
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        GrabPass{"_GrabTex"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            half4 _HighlightColor;
            half _HighlightFade;
            half _FresnelPower;
            half4 _FresnelColor;
            half _Tiling;
            float _Distort;


            sampler2D _MainTex; float4 _MainTex_ST;
            sampler2D _CameraDepthTexture; float4 _CameraDepthTexture_ST;
            sampler2D _GrabTex; float4 _GrabTex_ST; 

            struct appdata
            {
                float2 uv:TEXCOORD0;
                float4 positionOS : POSITION;
                float3 normalOS:NORMAL;   
            };

            struct v2f
            {
                float4 positionCS : SV_Position;
                float4 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 positionVS : TEXCOORD2;
                half3 normalWS : TEXCOORD3;
                half3 viewWS : TEXCOORD4;
            };
 
            v2f vert (appdata v)
            {
                v2f o;
                //o.pos = UnityObjectToClipPos(v.vertex);                
    
                o.positionWS = mul(unity_ObjectToWorld, v.positionOS.xyz);
                o.positionCS = UnityObjectToClipPos(v.positionOS);
                
                // 标准的观察空间转换
                o.positionVS = UnityObjectToViewPos(v.positionOS.xyz);
                
                o.normalWS = UnityObjectToWorldNormal(v.normalOS);
                
                // 计算视图方向（世界空间）
                o.viewWS = _WorldSpaceCameraPos - o.positionWS;
                
                o.uv.xy = v.uv;
                o.uv.zw = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            { 
                half4 c;
                half4 mainTex=tex2D(_MainTex,i.uv.zw+float2(0,_Time.y));
                half2 screenUV = i.positionCS.xy / _ScreenParams.xy;

                half4 depthMap = tex2D(_CameraDepthTexture, screenUV);
                //片段对应深度图中的像素在观察空间下的z值
                half depth = LinearEyeDepth(depthMap);//buildin管线不需要 _ZBufferParams

                half4 hightLight= depth + i.positionVS.z; //用+是因为左手坐标系下VS的z是负的，我们又需要作差来取得他们之间的差值
                hightLight*=_HighlightFade;
                hightLight=1-hightLight;
                hightLight*=_HighlightColor;
                hightLight =saturate(hightLight);

                //菲涅尔外发光要记住计算NV 和点乘和次数幂
                half3 N = i.normalWS;
                half3 V = i.viewWS;
                half NdotV=1-saturate(dot(N,V));
                half4 fresnel =pow(abs(NdotV),_FresnelPower);
                fresnel*=_FresnelColor;

                //整合菲涅尔和边缘发光效果
                c=hightLight+fresnel;
                c=c+mainTex*0.02;

                //流光动画
                float2 distortUV=lerp(screenUV,mainTex.rr,_Distort);
                half4 opaqueMap = tex2D(_GrabTex, distortUV);
                
                half4 distort =half4(opaqueMap.rgb,1);
                half mask=frac(i.uv.y*_Tiling+_Time.y);
                distort*=mask;
                c+=distort;
                return c;
            }
            ENDCG
        }
    }
}