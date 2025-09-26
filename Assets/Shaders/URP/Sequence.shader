//UV帧序列

Shader "aj7/URP/Sequence"
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,1)
        [NoScaleOffset]_MainTex("Main Texture",2D)="white"{}
        _Cols("Cols", Float) = 4
        _Rows("Rows", Float) = 3
        _FPS("FPS", Float) = 12
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniverslPipelie"
            "RenderType"="Opaque"
            "Queuqe"="Geometry+0"
        }
        Pass
        {
            Name "Pass"
            Tags
            {
            //LightMode:<None>
            }

            //RenderState
            Blend One Zero,One Zero
            Cull back
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
            half _Cols;
            half _Rows;
            half _FPS;
            CBUFFER_END




            //sampler2D _MainTex;
            TEXTURE2D(_MainTex);    //纹理的定义，如果是编译到GLES2.0平台，则相当于sampler2D _MainTex;否则就相当于Texture2D _MainTex;
            float4 _MainTex_ST;
            SAMPLER(sampler_MainTex);  //采样器的定义，如果是编译到GLES2.0平台，默认相当于空，否则就相当于samplerState sampler_MainTex;
            
            //#define smp sampler_MainTex
            //#define smp sampler_linear_clamp
            //SAMPLER(smp);

            //顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD;
            };

            //顶点着色器的输出
            struct Varyings
            {
                float4 positionCS : SV_Position;
                float2 uv : TEXCOORD;
            };

            //顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float3 positionWS = TransformObjectToWorld(v.positionOS);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.uv=v.uv;
                return o;
            }

            half GetFrameIndex()
            {
                half total = max(1, _Cols * _Rows);
                //关键，通过floor来织造一块时间停顿在一个图像上，然后立刻跳转，而不是缓慢平移
                half idx = (int)floor(_Time.y * max(1, _FPS)) % total;
                return idx; 
            }    
            //将UV映射到某一帧
            float2 ComputeUV(float2 uv,half frameIndex)
            {
                //Frame:[0,row*col-1].这里[0,8]
                half col = frameIndex % _Cols;
                half row = floor(frameIndex / _Cols);
                //0,0  1,0  2,0  0,1  1,1  2,1  0,2  1,2  2,2
                // 纹理帧从左上到右下排布，Unity UV 原点在左下，则可选择翻转行索引
                //0,2  1,2  2,2  0,1  1,1  2,1  0,0  1,0  2,0
                row = _Rows - 1 - row;
                float2 frameScale =float2(1/_Cols,1/_Rows);
                float2 frameOffset=float2(col,row)*frameScale;

                // 这里假设输入 uv 在 0~1 内；若有平铺，可用 frac(uv)
                float2 uvInFrame = uv; 
                uvInFrame= uvInFrame * frameScale + frameOffset;
                return uvInFrame;

            }
            half4 frag (Varyings i):SV_Target
            {
                //关键是如何获取uv?
                //是否可以写一个调整帧序列动画的shadrr？
                half4 c;
                half frameIndex=GetFrameIndex();


                float2 uvFrame =ComputeUV(i.uv,frameIndex);
                //return uvFrame.y/4;
                half4 mainTex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uvFrame);
                //c=mainTex;
                c=mainTex*_Color;
                //return 1 ;
                return c;
            }
            ENDHLSL
        }
    }
}