Shader "aj7/heatDistort_optimize"
{
    Properties
    {
        _DistortTex("Distort Texture",2D)="white"{}
        _Distort("SpeedX(X),SpeedY(Y),Distort(Z)",vector)=(0,0,0,0)
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" }
        GrabPass{"_GrabTexture"}
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            #include "UnityCG.cginc"

            sampler2D _GrabTexture;
            sampler2D _DistortTex;
            float4 _DistortTex_ST;
            float4 _Distort;


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 screenUV : TEXCOORD1;
            };
            
            v2f vert( appdata v) //语义函数
            {

                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);                
                o.uv = TRANSFORM_TEX(v.uv, _DistortTex)+_Distort.xy*_Time.y;
                //把裁剪后的区间从[-1,1]转换到[0,1]。可以直接用系统语句，=忽略不同版本的品目坐标差异
                //o.screenUV= i.screenUV.xy/i.screenUV.w*0.5+0.5  ;
                o.screenUV=ComputeScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed2 screenUV= screenPos.xy/_ScreenParams.xy;
                fixed4 distortTex= tex2D(_DistortTex,i.uv);
                float2 uv=lerp(i.screenUV.xy/i.screenUV.w,distortTex,_Distort.z);
                
                fixed4 grabTex= tex2D(_GrabTexture,uv);

                return grabTex;
            }
            ENDCG
        }
    }
}
