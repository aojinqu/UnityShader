//UV帧序列

Shader "aj7/URP/Sequence"
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,1)
        [NoScaleOffset]_MainTex("Main Texture",2D)="white"{}
        [Toggle]_UseR("Use R Channel", Float) = 0
        
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Source Blend", int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Destination Blend", int) = 1
        [Enum(BillBoard,1,VerticalBillBoard,0)]_BillboardType("BillBoard(1),VerticalBillBoard(0)",int) =1
        _Cols("Cols", Float) = 4
        _Rows("Rows", Float) = 3
        _FPS("FPS", Float) = 12
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Pass
        {
            Name "Pass"
            Tags
            {
            //LightMode:<None>
            }

            //RenderState
            Blend [_SrcBlend] [_DstBlend]
            Cull Off
            //ZTest LEqual
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
            half _UseR;
            int _BillboardType;
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
                //构建旋转后的基向量在模型本地空间下的坐标
                //计算相机世界坐标到本地空的向量单位化
                float3 viewDir =normalize(mul(GetWorldToObjectMatrix(),float4(_WorldSpaceCameraPos.xyz,1)));  //这里不对！！！一定要保重w分量是1，否则在计算的时候会给float3的这个pos自动补全一个w=0.导致计算错误
                viewDir.y*=_BillboardType;  //判断是否为垂直billboard
                float3 upDir=float3(0,1,0);
                //P.S 模型的本地空间是左手坐标系，所以这里是rightDir
                float3 rightDir=normalize(cross(viewDir,upDir));
                upDir=normalize(cross(rightDir,viewDir));
                //矩阵乘法的形式
                float4x4 M ={
                rightDir.x,upDir.x,viewDir.x,0,
                rightDir.y,upDir.y,viewDir.y,0,
                rightDir.z,upDir.z,viewDir.z,0,
                0,0,0,1
                };
                float3 newVertex=mul(M,v.positionOS);
                //向量乘法的形式
                //newVertex=rightDir*v.positionOS.x+upDir*v.positionOS.y+viewDir*v.positionOS.z;

                o.positionCS = TransformObjectToHClip(newVertex);
                o.uv=v.uv;

                return o;
            }

            int GetFrameIndex()
            {
                //half total = max(1, _Cols * _Rows);
                //关键，通过floor来织造一块时间停顿在一个图像上，然后立刻跳转，而不是缓慢平移
                int total = (int)(_Cols * _Rows);
                total = max(1, total);
                int idx = (int)floor(_Time.y * max(1, _FPS)) % total;
                
                return idx; 
            }    
            //将UV映射到某一帧
            float2 ComputeUV(float2 uv,int frameIndex)
            {
                //Frame:[0,row*col-1].这里[0,8]
                int col = int(frameIndex % _Cols);
                int row = int(frameIndex / _Cols); //关键！！这句不能用floor，会有精度问题导致row值错误
                //0,0  1,0  2,0  0,1  1,1  2,1  0,2  1,2  2,2
                // 纹理帧从左上到右下排布，Unity UV 原点在左下，则可选择翻转行索引
                //0,2  1,2  2,2  0,1  1,1  2,1  0,0  1,0  2,0
                row = _Rows - 1 - row;
                float2 frameScale = float2(1/_Cols,1/_Rows);   
                float2 frameOffset=float2(col,row)*frameScale;

                // 这里假设输入 uv 在 0~1 内；若有平铺，可用 frac(uv)
                float2 uvInFrame = uv; 
                uvInFrame= uvInFrame * frameScale + frameOffset;

                return uvInFrame;

            }
            half4 frag (Varyings i):SV_Target
            {
               
                half4 c;
                int frameIndex=GetFrameIndex();

                float2 uvFrame =ComputeUV(i.uv,frameIndex);
                //return uvFrame.y/4;
                half4 mainTex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uvFrame);
                
                c=mainTex*_Color;
                //UseR
                c.rgb = _UseR>0.5 ? c.a : c.rgb;
                //return 1;
                return c;
            }
            ENDHLSL
        }
        
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        Pass
        {
            Name "Pass"

            //RenderState
            Blend [_SrcBlend] [_DstBlend]
            Cull Off
            //ZTest LEqual
            ZWrite On
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 2.0
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "AutoLight.cginc" //包含阴影相关的函数

            half4 _Color;
            half _Cols;
            half _Rows;
            half _FPS;
            

            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _BillboardType;
            
            //顶点着色器的输入（模型的数据信息）
            struct appdata
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            //顶点着色器的输出
            struct v2f
            {
                float4 positionCS : SV_Position;
                float2 uv : TEXCOORD0;
            };

            int GetFrameIndex()
            {
                int total = (int)(_Cols * _Rows);
                total = max(1, total);
                int idx = (int)floor(_Time.y * max(1, _FPS)) % total;
                
                return idx; 
            }    
            //将UV映射到某一帧
            float2 ComputeUV(float2 uv,int frameIndex)
            {
                //Frame:[0,row*col-1].这里[0,8]
                int col = int(frameIndex % _Cols);
                int row = int(frameIndex / _Cols); //关键！！这句不能用floor，会有精度问题导致row值错误
                row = _Rows - 1 - row;
                float2 frameScale = float2(1/_Cols,1/_Rows);   
                float2 frameOffset=float2(col,row)*frameScale;

                float2 uvInFrame = uv; 
                uvInFrame= uvInFrame * frameScale + frameOffset;

                return uvInFrame;

            }
            //顶点着色器
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                //构建旋转后的基向量在模型本地空间下的坐标
                //计算相机世界坐标到本地空的向量单位化
                float3 viewDir =normalize(mul(unity_ObjectToWorld,float4(_WorldSpaceCameraPos.xyz,1)));  //这里不对！！！一定要保重w分量是1，否则在计算的时候会给float3的这个pos自动补全一个w=0.导致计算错误
                viewDir.y*=_BillboardType;  //判断是否为垂直billboard
                float3 upDir=float3(0,1,0);
                //P.S 模型的本地空间是左手坐标系，所以这里是rightDir
                float3 rightDir=normalize(cross(viewDir,upDir));
                upDir=normalize(cross(rightDir,viewDir));
                //矩阵乘法的形式
                float4x4 M ={
                rightDir.x,upDir.x,viewDir.x,0,
                rightDir.y,upDir.y,viewDir.y,0,
                rightDir.z,upDir.z,viewDir.z,0,
                0,0,0,1
                };
                float3 newVertex=mul(M,v.positionOS);
                //向量乘法的形式
                //newVertex=rightDir*v.positionOS.x+upDir*v.positionOS.y+viewDir*v.positionOS.z;

                o.positionCS = UnityObjectToClipPos(newVertex);
                o.uv=v.uv;
                return o;
            }


            half4 frag (v2f i):SV_Target
            {

                half4 c;
                int frameIndex=GetFrameIndex();

                float2 uvFrame =ComputeUV(i.uv,frameIndex);

                half4 mainTex=tex2D(_MainTex,uvFrame);
                
                c=mainTex*_Color;
                //UseR
                c.rgb=c.a;
                return c;
            }
            ENDHLSL
        }
        
    }    
}