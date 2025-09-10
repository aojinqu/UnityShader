Shader "aj7/OutlineEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0, 0.01)) = 0.002
        _OutlineThreshold ("Outline Threshold", Range(0, 1)) = 0.1
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
                float3 viewNormal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                // 将法线转换到视图空间
                o.viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                return o;
            }
            
            fixed4 _OutlineColor;
            float _OutlineThickness;
            float _OutlineThreshold;
            
            // 获取相邻像素的法线差异
            float GetNormalDifference(float2 uv, float3 centerNormal)
            {
                // 定义采样偏移（根据描边厚度调整）
                float2 offsets[4] = {
                    float2(_OutlineThickness, 0),
                    float2(-_OutlineThickness, 0),
                    float2(0, _OutlineThickness),
                    float2(0, -_OutlineThickness)
                };
                
                float totalDifference = 0;
                
                // 对四个方向进行采样
                for (int i = 0; i < 4; i++)
                {
                    // 采样相邻像素的法线
                    float3 sampleNormal = normalize(tex2D(_MainTex, uv + offsets[i]).rgb * 2.0 - 1.0);
                    
                    // 计算法线差异（使用点积）
                    float difference = 1.0 - dot(centerNormal, sampleNormal);
                    totalDifference += difference;
                }
                
                return totalDifference / 4.0;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // 采样主纹理
                fixed4 col = tex2D(_MainTex, i.uv);
                
                // 计算法线差异
                float normalDifference = GetNormalDifference(i.uv, normalize(i.viewNormal));
                
                // 如果差异超过阈值，则认为是边缘
                if (normalDifference > _OutlineThreshold)
                {
                    return _OutlineColor;
                }
                
                return col;
            }
            ENDCG
        }
    }
}
