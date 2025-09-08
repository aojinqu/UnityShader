// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unlit/LightModel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DiffuseIntensity ("Diffuse Intensity", Range(0,1)) = 1.0
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _SpecularIntensity ("Specular Intensity", Range(0,1)) = 1.0
        _Shininess("Shininess",Range(1,32))=12.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            half _DiffuseIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3 worldNormal : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);//关键。把物体空间坐标转换为世界坐标
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //最基础的lambert光照模型实现
                //Diffuse=amibient+LightColor*Kd*dot(N*L).其中N和L需要归一化为单位向量
                float4 ambient=unity_AmbientSky;
                half Kd=_DiffuseIntensity;
                fixed4 LightColor=_LightColor0;
                fixed3 N= normalize(i.worldNormal);
                fixed3 L= normalize(_WorldSpaceLightPos0);//顶点到光源的向量连线。默认参数为世界空间下的灯光位置
                fixed4 Diffuse=ambient + LightColor * Kd * max(0, dot(N, L));//要用max是因为N和L的夹角为钝角时会为负数，需要处理
                return Diffuse;
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            Blend One One 

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
        
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            half _DiffuseIntensity;
            float4 _SpecularColor;
            half _SpecularIntensity;
            half _Shininess;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);//关键。把法线从物体空间转换到世界空间,创建一个向上的法线n向量
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;//把物体空间坐标转换为世界坐标
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c=0;
                //实现光的衰减
                //fixed atten = Tex2D(_LightTexture0, i.uv);
                //return atten;
                //float2 lightCoord=mul(_LightTexture0,float4(i.worldPos,1)).xyz;
                //return lightCoord.x;  
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos)
                //最基础的lambert光照模型实现
                //Diffuse=amibient+LightColor*Kd*dot(N*L).其中N和L需要归一化为单位向量
                float4 ambient=unity_AmbientSky;
                half Kd=_DiffuseIntensity;
                fixed4 LightColor=_LightColor0;
                fixed3 N= normalize(i.worldNormal);
                fixed3 L= normalize(_WorldSpaceLightPos0);//顶点到光源的向量连线(即视线)。默认参数为世界空间下的灯光位置
                fixed4 Diffuse=LightColor * max(0, dot(N, L));//要用max是因为N和L的夹角为钝角时会为负数，需要处理
                c=Diffuse;

                //Phong模型，为lambert增加高光.有点没懂，这个公式物理上怎么推出来的？
                //Specular=SpecularColor*Ks*pow(max(0,dot(R,V)),shineness)
                //R=2*N*dot(N,L)-L
                float3 V= normalize(_WorldSpaceCameraPos- i.worldPos);//顶点到摄像机的向量连线
                float3 R= reflect(-L,N);//反射向量,简单做法.-L是入射向量
                //float3 R=2*N*dot(N,L)-L;
                half Ks=_SpecularIntensity;
                float4 Specular=_SpecularColor * Ks * pow(max(0,dot(R,V)),_Shininess);
                //c+=Specular ;
                
                //test Specular
                //float4 Specular = float4(1,1,1,1) * 1.0 * pow(max(0,dot(R,V)), 12.0);
                //return Specular;
                
                //Blinn-Phong
                //Specular=SpecularColor*Ks*pow(max(0,dot(N,H)),shineness)
                fixed3 H = normalize(L + V);//半程向量
                fixed4 BlinnSpecular=_SpecularColor*Ks*pow(max(0,dot(N,H)),_Shininess);
                c+=BlinnSpecular;
                return c;
            }
            ENDCG
        }
    }
}
