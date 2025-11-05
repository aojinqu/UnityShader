Shader "Custom/Minishader"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _Cutout("cutout", Range(-0.1, 1.1)) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode", float) = 2
    }
    SubShader
    {
        Pass
        {
            Cull [_CullMode]
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                // 如果不需要世界坐标UV，可以移除pos_uv
                // float2 pos_uv : TEXCOORD1;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutout;

            //顶点Shader - 修正版本
            v2f vert(appdata v)
            {
                v2f o;
                
                // 方法1：使用Unity内置函数（推荐）
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 方法2：如果坚持手动计算，需要正确处理
                // float4 pos_world = mul(unity_ObjectToWorld, v.vertex);
                // float4 pos_view = mul(UNITY_MATRIX_V, pos_world);
                // float4 pos_clip = mul(UNITY_MATRIX_P, pos_view);
                // o.pos = pos_clip;
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex); // 使用Unity宏
                
                return o;
            }

            //片元shader 
            float4 frag(v2f i) : SV_Target
            {
                half gradient = tex2D(_MainTex, i.uv).r;
                clip(gradient - _Cutout);
                return gradient.xxxx;
            }
            ENDCG
        }
    }
}