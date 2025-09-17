Shader "aj7/Fog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;

                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                //方法一：自定义雾效插值器
                float fogFactor: TEXCOORD3;
                //方法二：等于开启雾效时定义一个float类型的变量fogCoord
                //UNITY_FOG_COORDS(1)
                //方法三
                //无需额外定义雾效插值器，但需要将worldPos定义为float4，将计算出来的fogFactor存入worldPos.w中

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                float z= length(o.worldPos-_WorldSpaceCameraPos);//计算物体位置到摄像机的距离
                    // x = density / sqrt(ln(2)), useful for Exp2 mode
                    // y = density / ln(2), useful for Exp mode
                    // z = -1/(end-start), useful for Linear mode
                    // w = end/(end-start), useful for Linear mode
                    //float4 unity_FogParams;以上为其4个参数含义，可以用于获取end start的值
                #if defined(FOG_LINEAR)
                    o.fogFactor= saturate( z*unity_FogParams.z + unity_FogParams.w);//不能直接-z！！！！
                #elif defined(FOG_EXP)   
                    o.fogFactor=exp2(-z*unity_FogParams.y);
                #elif defined(FOG_EXP2)
                    
                    o.fogFactor=exp2(-pow(z*unity_FogParams.x,2));
                #endif
                //Unity内部雾效方法
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o;

            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 c =1;

                #if defined (FOG_LINEAR)||(FOG_EXP)||(FOG_EXP2)  
                    c=lerp( unity_FogColor,c,i.fogFactor);
                #endif

                // apply fog unity 内部方法
                //UNITY_APPLY_FOG(i.fogCoord, c);
                return c;
            }
            ENDCG
        }
    }
}
