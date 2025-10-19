Shader "GroundDisappear"
{
    Properties
    {
        _Radius("Radius", Float) = 0
        _FadeRange("FadeRange", Float) = 2
        _OutlineColor("OutlineColor", Color) = (0,0.7479331,1,0)
        [Toggle(_DISAPPEARENABLED_ON)] _DisappearEnabled("DisappearEnabled", Float) = 0
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
        Cull Back
        
        Pass 
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile __ _DISAPPEARENABLED_ON
            #include "UnityCG.cginc"

            int StartPosCount;
            float4 StartPosArry[5];
            float _Radius;
            float _FadeRange;
            float4 _OutlineColor;

            struct appdata
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };

            struct v2f 
            {
                float4 pos:SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert (appdata v) 
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target 
            {
                fixed4 c = 0;

                //Lambert光照
                fixed NdotL = dot( i.worldNormal , _WorldSpaceLightPos0 );
                fixed diffuse = (NdotL * 0.5 + 0.5) * 0.4;

                #ifdef _DISAPPEARENABLED_ON
                    //不同的遮罩位置触发的效果
                    float fadeMin = _Radius - _FadeRange;
                    float fadeMax = _Radius;
                    float outline = 1;
                    for(uint j=0;j<StartPosCount;j++)
                    {
                        float3 startPos = StartPosArry[j].xyz;
                        // saturate((x - min)/(max - min))
                        // float fade = smoothstep( fadeMin , fadeMax , distance( startPos , i.worldPos));
                        float fade = saturate((distance( startPos , i.worldPos) - fadeMin)/(fadeMax-fadeMin));
                        outline *= fade;
                    }
                    clip( 0.999 - outline);
                    c =  outline * _OutlineColor + diffuse;
                #else
                    c = diffuse;
                #endif
                // UNITY_APPLY_FOG(_unity_fogCoord, c);
                return c;
            }

            ENDCG

        }

    }
}