Shader "aj7/heatDistort"
{
    Properties
    {
        _DistortTex("Distort Texture",2D)="white"{}
        _Distort("SpeedX(X),SpeedY(Y),Distort(Z)",vector)=(0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
        GrabPass{"_GrabTexture"}
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

            struct v2f
            {
                float2 uv : TEXCOORD0;
            };
            
            v2f vert //语义函数
            (
                float4 vertex : POSITION,
                float2 uv : TEXCOORD0,
                out float4 pos : SV_POSITION
            )
            {
                pos = UnityObjectToClipPos(vertex);
                v2f o;
                o.uv = TRANSFORM_TEX(uv, _DistortTex)+_Distort.x*_Time.y;//先把坐标算出来,第二句“用坐标取图”
                return o;
            }
            //需要这样因为VPOS会和appdata中的vpos重名 所以需要这样写
            fixed4 frag (v2f i,UNITY_VPOS_TYPE screenPos : VPOS) : SV_Target
            {
                fixed2 screenUV= screenPos.xy/_ScreenParams.xy;
                fixed4 distortTex= tex2D(_DistortTex,i.uv); //上面算好的 i.uv 去“真正采样”扭曲贴图，得到颜色/向量值
                float2 uv=lerp(screenUV,distortTex.xy,_Distort.z);

                fixed4 grabTex= tex2D(_GrabTexture,uv);

                return grabTex;
            }
            ENDCG
        }
    }
}
