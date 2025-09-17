Shader "aj7/effect"
{
    Properties
    {
        [Header(Base)]
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        _Intensity("Intensity", Range(-4, 4)) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Source Blend", int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Destination Blend", int) = 1
        [Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", int) = 1
        _UVChangeX("UV Change X", float) = 1
        _UVChangeY("UV Change Y", float) = 1
        [Enum(Off,0,On,1)]_ZWrite("ZWrite", Float) = 0

        [Header(Mask)]
        [Toggle]_MaskEnabled("Mask Enabled", Int) = 0
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _UV2ChangeX("UV Change X", float) = 1
        _UV2ChangeY("UV Change Y", float) = 1

        [Header(Distortion)]
        [Toggle]_DistortionEnabled("Distortion Enabled", Int) = 0
        _DistortionTex ("Distortion Texture", 2D) = "white" {}
        _Distort("Distortion", Range(0, 1)) = 0
        _UV3ChangeX("UV Change X", float) = 1
        _UV3ChangeY("UV Change Y", float) = 1


    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        Tags { "RenderType"="Opaque" }
        LOD 100
        Zwrite [_ZWrite]
        Pass
        {
        //混合模式 blend的效果通过texture 里的下拉框实现
            Blend [_SrcBlend] [_DstBlend]
            Cull [_Cull]
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //变体
            #pragma multi_compile _ _MASKENABLED_ON
            #pragma multi_compile _ _DISTORTIONENABLED_ON
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _MaskTex;
            sampler2D _DistortionTex;
            float4 _MainTex_ST;
            float4 _MaskTex_ST;
            float4 _DistortionTex_ST;

            float4 _Color;
            half _Intensity;
            float _UVChangeX,_UVChangeY;
            float _UV2ChangeX,_UV2ChangeY;
            float _UV3ChangeX,_UV3ChangeY;
            float _Distort;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex)+ float2(_UVChangeX, _UVChangeY)*_Time.y;
                #if _MASKENABLED_ON
                o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex)+ float2(_UV2ChangeX, _UV2ChangeY)*_Time.y;
                #endif
                #if _DISTORTIONENABLED_ON
                o.uv2 = TRANSFORM_TEX(v.uv, _DistortionTex)+ float2(_UV3ChangeX, _UV3ChangeY)*_Time.y;
                #endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //正常采样
                fixed4 c = tex2D(_MainTex, i.uv.xy);
                //uv扭曲采样
                #if _DISTORTIONENABLED_ON     
                    fixed4 distortTex = tex2D(_DistortionTex, i.uv2);                           
                    float2 distort = lerp(i.uv.xy,distortTex.xy,_Distort);  //线性插值(a,b,alpha)，返回(a,b)中间平滑过渡
                    c = tex2D(_MainTex,distort);
                #endif

                c *=_Color * _Intensity;

                //遮罩
                #if _MASKENABLED_ON
                    fixed4 maskTex = tex2D(_MaskTex, i.uv.zw);
                    c *=  maskTex;
                #endif
                return c;
            }
            ENDCG
        }
    }
}
