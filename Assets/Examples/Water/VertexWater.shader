Shader "aj7/URP/VertexWater"
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,1)
        _MainTex("Main Texture",2D)="white"{}
        _WaveHeight("Wave Height",Float)=1
        _WaveLength("Wave Length",Float)=10
        _WaveSpeed("Wave Speed",Float)=1
        _Direction("Direction",Vector)=(1,0,0,0)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }
        Pass
        {
            Name "VertexWater"

            //RenderState
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back 
            ZTest LEqual
            ZWrite On
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            half _WaveHeight;
            half _WaveLength;
            half _WaveSpeed;
            half4 _Direction;
            CBUFFER_END


            TEXTURE2D(_MainTex);    //纹理的定义，如果是编译到GLES2.0平台，则相当于sampler2D _MainTex;否则就相当于Texture2D _MainTex;
            SAMPLER(sampler_MainTex);  //采样器的定义，如果是编译到GLES2.0平台，默认相当于空，否则就相当于samplerState sampler_MainTex;
            float4 _MainTex_ST;

            //顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            //顶点着色器的输出
            struct Varyings
            {
                float4 positionCS : SV_Position;
                float2 uv : TEXCOORD0;
            };

            //顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                //制造波浪效果
                half k = 2 * PI / _WaveLength;
                half2 d=normalize(_Direction.xy);
                half f = k *(dot(v.positionOS.xz, d)-_WaveSpeed*_Time.y);

                v.positionOS.x += d.x*cos(f)*_WaveHeight;
                v.positionOS.y = sin(f) * _WaveHeight;
                v.positionOS.z += d.y*cos(f)*_WaveHeight;

                
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            half4 frag (Varyings i):SV_Target
            {
                half4 c;
                half4 mainTex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                c=mainTex*_Color;
                return c;
            }
            ENDHLSL
        }
    }
    
}