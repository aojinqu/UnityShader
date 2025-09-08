Shader "Unlit/Character"
{
    Properties
    {
        [Header(Base)]
        _MainTex ("Main Texture", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest ("ZTest", int) = 0
        [Header(Dissolve)]
        [Toggle]_DissolveEnabled("Dissolve Enabled", Int) = 0
        _DissolveTex ("DissolveTexture", 2D) = "white" {}
        [Header(Ramp)]
        _RampTex ("RampTexture", 2D) = "white" {}
        _Color("Color",Color) = (0,0,0,0)  //默认黑色
        _Clip("Clip",Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "Queue"="Geometry" }
        LOD 100
        ZTest [_ZTest]
        Cull back
        Blend Off

        UsePass "aj7/XRay/XRay"
        
        Pass
        {
            //shadow caster 必不可少。它储存了深度信息
            Tags{"LightMode"="ForwardBase"} //写光照shader一定要把前向渲染路径写明白！！！！
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //定义的变体名字要和属性中定义的名字一致，并转大写。否则会失效.若为开关则一定要命名为_ON
            #pragma multi_compile _ _DISSOLVEENABLED_ON
            //#pragma multi_compile_fwdbase
            #pragma multi_compile Directional SHADOWS_SCREEN //减少变体数量

            #include "UnityCG.cginc"
            #include "AutoLight.cginc" //包含阴影相关的函数

            sampler2D _MainTex;
            sampler2D _DissolveTex;
            sampler _RampTex;
            float4 _MainTex_ST;
            float4 _DissolveTex_ST;
            float4 _Color;
            fixed _Clip; //不能设置为float4，它只是一个小数而已

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                //float4 dissolveUV : TEXCOORD1; // 本来如果只需要uv则定义为float2，但还需要保留mainTEX的uv，所以要用float4 //有点浪费，可以优化掉用uv来做，此时uv类型从float2变为float4
                
                float4 worldPos : TEXCOORD1; //用于存储顶点的世界坐标
                UNITY_SHADOW_COORDS(2) // 用于存储阴影坐标
                float4 pos : SV_POSITION;

            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = v.uv.xy;
                
                o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex); // 新增
                o.worldPos=mul(unity_ObjectToWorld,v.vertex);//顶点空间变换到世界
                TRANSFER_SHADOW(o) 
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);   
                 
                //1.在v2f中添加UNITY_SHADOW_COORDS(idx),unity会自动声明一个叫_ShadowCoord的float4变量，用作阴影的采样坐标.
                //2.在顶点着色器中添加TRANSFER_SHADOW(o)，用于将上面定义的_ShadowCoord纹理采样坐标变换到相应的屏幕空间纹理坐标，为采样阴影纹理使用.
                //3.在片断着色器中添加UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos)，其中atten即存储了采样后的阴影.
                                
                fixed4 c;
                // sample the texture
                fixed4 tex = tex2D(_MainTex, i.uv);
                c=tex*atten;

                //利用变体，节省时间
                #if _DISSOLVEENABLED_ON
                fixed4 dissolve = tex2D(_DissolveTex, i.uv.zw); // 使用预先计算的dissolveUV
                c += _Color;
                clip(dissolve.r-_Clip);
                float4 ramp = tex1D(_RampTex, smoothstep(_Clip,_Clip+0.1,dissolve.r));
                c += ramp;
                #endif
                

                return c;
            }
            ENDCG
        }
        
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
                SHADOW_CASTER_FRAGMENT(i);  
            }
            ENDCG
            //添加"LightMode" = "ShadowCaster"的Pass.
            //1.appdata中声明float4 vertex:POSITION;和half3 normal:NORMAL;这是生成阴影所需要的语义.
            //2.v2f中添加V2F_SHADOW_CASTER;用于声明需要传送到片断的数据.
            //3.在顶点着色器中添加TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)，主要是计算阴影的偏移以解决不正确的Shadow Acne和Peter Panning现象.
            //4.在片断着色器中添加SHADOW_CASTER_FRAGMENT(i)       
        }
    }
}
