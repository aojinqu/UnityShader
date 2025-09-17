Shader "aj7/XRay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        //Cull Off
        Blend One One //加色法混合
        ZTest Greater //只渲染深度值比当前更大的像素
        ZWrite Off
        Pass
        {
            Name "XRay"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c=0;
                float3 V =normalize(_WorldSpaceCameraPos-i.worldPos);
                float3 N=normalize(i.worldNormal);
                float VdotN=dot(V,N);//模仿菲涅尔效应。边缘黑色中间白色。
                float fresnel= 2.0*pow(1.0-VdotN,2.0);//指数越大，边缘越黑
                c.rgb=fresnel*float3(1,1,0);//加上自发光颜色

                fixed v=frac(i.worldPos.y*20-_Time.y);//画出一条条扫描线，随y的周期变化.不要用乘法，会超出0-1范围
                c.rgb*=v;
                return c;
            }
            ENDCG
        }
    }
}
