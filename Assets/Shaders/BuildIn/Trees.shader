Shader "aj7/Trees"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        //LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 
            
            #include "UnityCG.cginc"
            
            //fixed4 _Color;// 被下面三条语句取代了
            UNITY_INSTANCING_BUFFER_START(prop)
            UNITY_DEFINE_INSTANCED_PROP(fixed4,_Color)
            UNITY_INSTANCING_BUFFER_END(prop)


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 wPos:TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o); //把instance ID从顶点着色器传到片断着色器

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv=v.uv;
                o.wPos=mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                return i.wPos.y*0.15+UNITY_ACCESS_INSTANCED_PROP(prop,_Color );
            }
            ENDCG
        }
    }
}
