// Upgrade NOTE: replaced 'defined FOG_COMBINED_WITH_WORLD_POS' with 'defined (FOG_COMBINED_WITH_WORLD_POS)'

Shader"aj7/MyPBR"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalTex ("Normal Map", 2D) = "bump" {}
        _MetallicTex ("Metallic(R) Smoothness(G) AO(B)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _AO ("AO", Range(0,1)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

	    // ---- forward rendering base pass:
        Pass
        {
            Name "FORWARD"
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            // compile directives
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"
            #include "../Shaders/CGIncludes/MYPBR.cginc" // 包含自定义的GI相关函数

            sampler2D _MainTex;
            sampler2D _MetallicTex;
            sampler2D _NormalTex;
            float4 _MainTex_ST;
            float4 _MetallicTex_ST;
            float4 _NormalTex_ST;
            half _Glossiness;
            half _Metallic;
            fixed4 _Color;
            fixed4 _AO;


            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0; // _MainTex
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                #if UNITY_SHOULD_SAMPLE_SH
                    half3 sh : TEXCOORD3; // SH
                #endif
                //切线空间需要的矩阵
                float3 tSpace0 : TEXCOORD4;
                float3 tSpace1 : TEXCOORD5;
                float3 tSpace2 : TEXCOORD6; 
                UNITY_FOG_COORDS(7)
                UNITY_SHADOW_COORDS(8)
            };

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0; // _MainTex
                float2 texcoord1 : TEXCOORD1; // lightmap
                float2 texcoord2 : TEXCOORD2; // dynamic lightmap
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            // vertex shader
            v2f vert(appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                //顶点空间的计算
                //世界空间下的切线
                half3 worldTangent = UnityObjectToWorldDir(v.tangent);
                //切线方向
                fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                //世界空间下的副切线
                half3 worldBinormal = cross(o.worldNormal, worldTangent) * tangentSign;
                //切线矩阵
                o.tSpace0 = float3(worldTangent.x,worldBinormal.x,worldNormal.x);
                o.tSpace1 = float3(worldTangent.y,worldBinormal.y,worldNormal.y);
                o.tSpace2 = float3(worldTangent.z,worldBinormal.z,worldNormal.z);

                o.worldPos.xyz = worldPos;
                //o.worldNormal = worldNormal;

                // SH/ambient and vertex lights               
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                    o.sh = 0;
                    // Approximated illumination from non-important point lights
                    #ifdef VERTEXLIGHT_ON
                        o.sh += Shade4PointLights (
                        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                        unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                        unity_4LightAtten0, worldPos, worldNormal);
                    #endif
                    o.sh = ShadeSHPerVertex (worldNormal, o.sh);
                #endif

                UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy); // pass shadow and, possibly, light cookie coordinates to pixel shader
                UNITY_TRANSFER_FOG(o, o.pos); 
                return o;
            }

            // fragment shader
            fixed4 frag(v2f i) : SV_Target
            {
                UNITY_EXTRACT_FOG(i);
                float3 worldPos = i.worldPos.xyz;

                //输出材质信息
                SurfaceOutputStandard o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
                float4 mainTex=tex2D(_MainTex, i.uv);

                half3 normalTex = UnpackNormal(tex2D(_NormalTex,i.uv));
                half3 worldNormal = half3(dot(i.tSpace0,normalTex),dot(i.tSpace1,normalTex),dot(i.tSpace2,normalTex));

                o.Albedo = mainTex.rgb *_Color;      // base (diffuse or specular) color
                o.Normal = worldNormal;
                o.Emission = 0.0;
                fixed4 metallicTex =tex2D(_MetallicTex, i.uv);
                o.Metallic = metallicTex.r *_Metallic;      // 0=non-metal, 1=metal
                o.Smoothness = metallicTex.g *_Glossiness;    // 0=rough, 1=smooth
                o.Occlusion = metallicTex.b *_AO;     // occlusion (default 1)
                o.Alpha = 1;
                o.Occlusion = 1.0;

                 // compute lighting & shadowing factor
                UNITY_LIGHT_ATTENUATION(atten, i, worldPos)
                // Setup lighting environment
                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;
                gi.light.color = _LightColor0.rgb;
                gi.light.dir = _WorldSpaceLightPos0.xyz;
                // Call GI (lightmaps/SH/reflections) lighting function
                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = worldPos;
                giInput.worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                giInput.atten = atten;
                
                    giInput.lightmapUV = 0.0;
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                    giInput.ambient = i.sh;
                #else
                    giInput.ambient.rgb = 0.0;
                #endif
                    giInput.probeHDR[0] = unity_SpecCube0_HDR;
                    giInput.probeHDR[1] = unity_SpecCube1_HDR;
                #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
                    giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
                #endif
                #ifdef UNITY_SPECCUBE_BOX_PROJECTION
                    giInput.boxMax[0] = unity_SpecCube0_BoxMax;
                    giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
                    giInput.boxMax[1] = unity_SpecCube1_BoxMax;
                    giInput.boxMin[1] = unity_SpecCube1_BoxMin;
                    giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
                #endif
                LightingStandard_GI1(o, giInput, gi);
                //return fixed4(gi.indirect.diffuse,1);
                //PBS的核心计算
                fixed4 c = LightingStandard1(o, giInput.worldViewDir, gi);
                UNITY_APPLY_FOG(_unity_fogCoord, c); // apply fog
                UNITY_OPAQUE_ALPHA(c.a);// 设定a为1
                return c;
}


            ENDCG

        }

    }

}
