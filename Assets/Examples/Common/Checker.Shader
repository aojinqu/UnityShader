Shader "aj7/Commen/Checker"
{
    Properties
    {
        _Color("Color",color)=(1,1,1,1)
        _Repeat("Repeat",float)=15
    }

    //URP
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline" 
            "RenderType"="Opaque"
            "Queue"="Geometry+0"
        }
        //BLEND One One 
        Cull FRONT
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl" // 确保包含雾效函数 
             
            CBUFFER_START(UnityPerMaterial)
                float _Repeat;
                half4 _Color;
            CBUFFER_END

            struct Attributes  //appata
            {
                float2 uv:TEXCOORD0;
                float4 vertexOS : POSITION;
                float3 normalOS:NORMAL;  //OS: Object Space
            };

            struct Varyings    //vertex
            {
                float2 uv:TEXCOORD0;
                float4 vertexCS : SV_POSITION;  //CS:Clip Space
                float3 worldPosWS:TEXCOORD1;
                float3 normalWS:TEXCOORD2;  //WS:World Space
                float4 vertexOS:TEXCOORD3;  
                float fogCoord:TEXCOORD4;
            };

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertexOS=v.vertexOS;
                o.uv=v.uv*_Repeat;
                o.normalWS=TransformObjectToWorldNormal (v.normalOS);                
                o.worldPosWS =TransformObjectToWorld(v.vertexOS);
                o.vertexCS = TransformObjectToHClip(v.vertexOS);
                //雾效
                o.fogCoord = ComputeFogFactor(o.vertexCS.z);  //传入深度值
                return o;
            } 

            half4 frag (Varyings i) : SV_Target
            {
                half4 c;
                //经典用uv或者OS坐标得出(0,1)范围再制作想要的纹理图
                half2 uv_check= floor(i.uv*2)/2;
                c= frac(uv_check.x+uv_check.y)*2;
                //经典遮罩制作方法
                half mask =i.vertexOS.y+0.55;
                c*=mask;
                c*=_Color;
                c.rgb=MixFog(c,i.fogCoord);
                return c;
            }
            ENDHLSL
        }
    }

    //BuildIn
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull FRONT
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            float _Repeat;
            half4 _Color;


            struct appdata
            {
                float2 uv:TEXCOORD0;
                float4 vertexOS : POSITION;
                float3 normalOS:NORMAL;  //OS: Object Space
            };

            struct v2f
            {
                float2 uv:TEXCOORD0;
                float4 vertexOS : SV_POSITION;
                float3 worldPosWS:TEXCOORD1;
                float3 normalWS:TEXCOORD2;  //WS:World Space
                float3 ObjectPosOS:TEXCOORD3;
            };
 
            v2f vert (appdata v)
            {
                v2f o;
                //o.pos = UnityObjectToClipPos(v.vertex);                

                o.vertexOS = UnityObjectToClipPos(v.vertexOS);
                o.uv=v.uv*_Repeat;
                o.ObjectPosOS=v.vertexOS;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            { 
                half4 c;
                //经典用uv或者OS坐标得出(0,1)范围再制作想要的纹理图
                half2 uv_check= floor(i.uv*2)/2;
                c= frac(uv_check.x+uv_check.y)*2;
                //经典遮罩制作方法
                half mask =i.ObjectPosOS.y+0.55;
                c*=mask;
                c*=_Color;
                return c;
            }
            ENDCG
        }
    }
}
