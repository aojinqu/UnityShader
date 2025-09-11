// Upgrade NOTE: replaced 'defined defined' with 'defined (defined)'

Shader "aj7/Globalillumination"
{
    Properties
    {
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }
        Tags { "LightMode"="ForwardBase" } // 指定光照模式为ForwardBase
        LOD 100 // 设置LOD等级为100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert // 指定顶点着色器函数为vert
            #pragma fragment frag // 指定片段着色器函数为frag
            #pragma multi_compile_fwdbase // 必须加上这个宏，才能使用LightON宏
            #include "UnityCG.cginc" // 包含Unity的通用CG函数
            #include "Lighting.cginc" // 包含光照相关的函数
            #include "AutoLight.cginc" // 包含自动光照相关的函数
            //#include "./CGIncludes/MYGI.cginc"//不能直接这样写，一定要返回到shader，原因不明
            #include "../Shaders/CGIncludes/MYGI.cginc" // 包含自定义的GI相关函数

            struct appdata
            {
                float4 vertex : POSITION; // 顶点位置
                half3 normal: NORMAL; // 顶点法线
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON) // 如果启用了光照贴图
                float4 texcoord1: TEXCOORD1;  // 光照贴图的UV坐标
                #endif
            };

            struct v2f
            {
                float4 vertex : SV_POSITION; // 裁剪空间的顶点位置
                float3 worldPos : TEXCOORD0; // 世界空间的顶点位置
                half3 worldNormal : TEXCOORD1; // 世界空间的法线
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON) // 如果启用了光照贴图
                float4 lightmapUV : TEXCOORD2; // 光照贴图的UV坐标
                #endif
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex); 
                o.worldPos = mul(unity_ObjectToWorld, v.vertex); 
                o.worldNormal = UnityObjectToWorldNormal(v.normal); // 将物体空间的法线转换到世界空间
                #if defined(LIGHTMAP_ON) 
                o.lightmapUV.xy = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw; // 计算光照贴图的UV坐标
                #endif
                #if defined (DYNAMICLIGHTMAP_ON)
                o.lightmapUV.zw = v.texcoord1 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw; // 计算动态光照贴图的UV坐标
                #endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                SurfaceOutput o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutput, o); // 初始化SurfaceOutput结构体
                o.Albedo = fixed3(1,1,1); // 设置反照率为白色
                o.Normal = normalize(i.worldNormal); // 设置法线为世界空间的法线

                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi); // 初始化UnityGI结构体
                gi.light.color = _LightColor0; // 设置平行光的颜色
                gi.light.dir = _WorldSpaceLightPos0; // 设置平行光的方向
                gi.indirect.diffuse = 0; // 初始化间接漫反射光为0
                gi.indirect.specular = 0; // 初始化间接镜面反射光为0

                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput); // 初始化UnityGIInput结构体
                giInput.light = gi.light; // 设置光源信息
                giInput.worldPos = i.worldPos; // 设置世界空间的顶点位置
                giInput.worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos); // 计算从顶点到相机的视线方向
                giInput.atten = 1.0; // 设置光照衰减为1
                giInput.ambient = 0; // 设置环境光为0
                #if defined (LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                giInput.lightmapUV = i.lightmapUV; // 设置光照贴图的UV坐标
                #endif 

                LightingLambert_GI1(o, giInput, gi); // 计算光照，更新gi中的间接光信息
                //return fixed4(gi.indirect.diffuse, 1); // 返回间接漫反射光的颜色
                fixed4 c = LightingLambert1(o, gi); // 计算最终光照颜色
                //return 1;
                return c; // 返回最终颜色
            }
            ENDCG
        }
        //实时阴影
        Pass
        {

            Tags{"LightMode"="ShadowCaster"} //写光照shader一定要把前向渲染路径写明白！！！！
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile _ _DISSOLVEENABLED_ON


            #include "UnityCG.cginc"
            #include "AutoLight.cginc" //包含阴影相关的函数
            
            struct appdata
            {
                float4 vertex:POSITION;
                half3 normal:NORMAL;
                float2 uv: TEXCOORD0; 
            };
            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 pos: SV_POSITION; //由vertex改名而来，因为TRANSFER_SHADOW 进入到实际取的是 .pos 的顶点
                float4 worldPos : TEXCOORD1; //用于存储顶点的世界坐标
                //V2F_SHADOW_CASTER;
                UNITY_SHADOW_COORDS(2)
            };

            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;//关键！！！！！图和
            float _Clip;

            v2f vert(appdata v) 
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _DissolveTex);  
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

                return o;
            }
 
            fixed4 frag(v2f i):SV_Target
            {

                #if _DISSOLVEENABLED_ON
                fixed4 dissolve = tex2D(_DissolveTex, i.uv); // 使用预先计算的dissolveUV
                clip(dissolve.r-_Clip);
                #endif
                //添加"LightMode" = "ShadowCaster"的Pass.
                //1.appdata中声明float4 vertex:POSITION;和half3 normal:NORMAL;这是生成阴影所需要的语义.
                //2.v2f中添加V2F_SHADOW_CASTER;用于声明需要传送到片断的数据.
                //3.在顶点着色器中添加TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)，主要是计算阴影的偏移以解决不正确的Shadow Acne和Peter Panning现象.
                //4.在片断着色器中添加SHADOW_CASTER_FRAGMENT(i)                       
                SHADOW_CASTER_FRAGMENT(i);  
            }
            ENDCG

        }      
        //meta pass此处没写。
        //一般都不会编译，只有在做间接光的时候会被编译  
    }
}
