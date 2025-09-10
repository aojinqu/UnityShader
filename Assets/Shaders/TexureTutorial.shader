Shader "Aj7/Texuretutiol"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Normal]_NormalTex ("Normal Map", 2D) = "bump" {}
        [IntRange]_Mipmap("MipMap level", Range(0,10)) = 0
        [KeywordEnum(Repeat,Clamp)]_WrapMode("Wrap Mode", int) = 0
        [MainCube]_CubeMap("Cubemap", CUBE) = "white" {}
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
            //这里不需要用到程序变化，只有美术的设置变化，所以用shaderfeature比multi_complex更省资源    
            #pragma shader_feature _WRAPMODE_REPEAT _WRAPMODE_CLAMP  

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 localPos : TEXCOORD1;
                float3 worldlPos : TEXCOORD2;
                half3 worldNormal : TEXCOORD3;
                //切线转置矩阵
                float3 tSpace0:TEXCOORD4;
                float3 tSpace1:TEXCOORD5;       
                float3 tSpace2:TEXCOORD6;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            int _Mipmap;
            samplerCUBE _CubeMap;
            v2f vert (appdata v)
            {
                v2f o;
                o.localPos=v.vertex.xyz;
                o.worldlPos=mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                //计算切线转置矩阵
                half3 worldTangent = UnityObjectToWorldDir(v.tangent);
                fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 worldBinormal = cross(o.worldNormal, worldTangent) * tangentSign;
                o.tSpace0 = float3(worldTangent.x,worldBinormal.x,o.worldNormal.x);
                o.tSpace1 = float3(worldTangent.y,worldBinormal.y,o.worldNormal.y);
                o.tSpace2 = float3(worldTangent.z,worldBinormal.z,o.worldNormal.z);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                #ifdef _WRAPMODE_REPEAT
                    //重复模式。取uv的小数部分即可
                    i.uv = frac(i.uv);
                #endif
                #ifdef _WRAPMODE_CLAMP
                    //夹紧模式。取uv的0-1范围
                    i.uv = clamp(i.uv,0,1);
                #endif
                float4 mipMapUV= float4(i.uv,0,_Mipmap);
                //tex2Dlod函数可以指定mipmap等级采样贴图            
                //第二个参数为float4类型，xy为uv坐标，z为0，w为mipmap等级
                fixed4 c = tex2Dlod(_MainTex, mipMapUV);
                

                //法线贴图,记得归一化！！！
                //该做法是只有一个面的，如果要物体在每个面上都有法线贴图的凹凸，则需要正确计算每个点的切线空间
                fixed3 normalTex= UnpackNormal(tex2D(_NormalTex,i.uv));
                fixed3 N1=normalize(normalTex);
                fixed3 L=_WorldSpaceLightPos0.xyz;
                //return max(0,dot(N1,L));

                //真正的加了法线贴图后的物体世界坐标向量
                //做完切线空间后，就可以把法线贴图应用于所有物体上了
                half3 worldNormal = half3(dot(i.tSpace0,normalTex),dot(i.tSpace1,normalTex),dot(i.tSpace2,normalTex));
                //return max(0,dot(worldNormal,L));


                //天空盒
                fixed4 cubemap=texCUBE(_CubeMap,i.localPos);                
 
                //V,N,R
                fixed3 V= normalize (UnityWorldSpaceViewDir(i.worldlPos));
                fixed3 N=normalize(worldNormal);
                fixed3 R=reflect(-V,N);
                //Cube采样,关键是用什么uv来采样？答案是本地空间
                cubemap=texCUBE(_CubeMap,R);                
                //return cubemap;

                //反射探针中当前激活的CubeMap存储在unity_SpecCube0当中，必须要用UNITY_SAMPLE_TEXCUBE进行采样，然后需要对其进行解码
                half4 cubemap_reflect = UNITY_SAMPLE_TEXCUBE (unity_SpecCube0, R);
                half3 skyColor = DecodeHDR (cubemap_reflect, unity_SpecCube0_HDR);
                return fixed4(skyColor, 1.0);

            }
            ENDCG
        }
    }
}
