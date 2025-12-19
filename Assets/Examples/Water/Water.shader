Shader "aj7/URP/Water"
{
    Properties
    {
        _SurfaceColor("Surface Color (Near Surface = Darker)", Color) = (0.02, 0.18, 0.35, 0.85)
        _DeepColor("Deep Color (Deeper = Lighter)", Color) = (0.35, 0.65, 0.85, 0.85)
        _DepthMax("Depth Max (World Units)", Range(0.1, 20)) = 5
        [Header(Foam)]
        _FoamRange("Foam Range", Range(0.05, 2)) = 0.8
        _FoamTex("Foam Texture",2D)="white"{}
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _WaterSpeed("Foam Speed", Range(0, 1)) = 0.2
        _FoamNoise("Foam Noise", Range(0, 1)) = 0.5
        [Header(Distort)]
        _DistortTex("Distort Texture",2D)="white"{}
        _Distort("Distort", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }
        LOD 100
        Pass
        {
            Name "Water"
            Tags { "LightMode" = "UniversalForward" }

            // 踩坑：水面一定要关闭深度写入（ZWrite Off）
            // 原因：透明物体写入深度会让后续像素/物体被深度测试剔除，水下物体就“被挡掉”，表现成一片黑/没有渐变
            Blend One OneMinusSrcAlpha
            ZWrite Off
            Cull Back

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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _SurfaceColor;
                half4 _DeepColor;
                half _DepthMax;
                half _FoamRange;
                half _WaterSpeed;
                half4 _FoamColor;   
                half _FoamNoise;
                half _Distort;
            CBUFFER_END

            TEXTURE2D(_DistortTex); //声明扭曲纹理
            SAMPLER(sampler_DistortTex); //声明扭曲纹理的采样器
            float4 _DistortTex_ST; //扭曲纹理的缩放和偏移

            TEXTURE2D(_FoamTex);     //主纹理
            SAMPLER(sampler_FoamTex);  //主纹理的采样器
            float4 _FoamTex_ST; //主纹理的缩放和偏移
 
            //顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
                float4 uv : TEXCOORD0; //.xy=foamUV
            };

            //顶点着色器的输出
            struct Varyings
            {
                float4 positionCS : SV_Position;
                float4 uv : TEXCOORD0; // xy = distortUV,zw = foamUV
                float3 positionVS:TEXCOORD1;
                float3 positionWS:TEXCOORD2;
                float4 screenPos:TEXCOORD3;
            };

            //顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionVS=TransformWorldToView(o.positionWS);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                //计算得到泡沫纹理采样需要的顶点世界空间下的坐标值的流动效果
                o.uv.zw=o.positionWS.xz*_FoamTex_ST.xy+_Time.y*_WaterSpeed;
                //计算得到水下扭曲纹理的流动UV
                o.uv.xy=TRANSFORM_TEX(v.uv,_DistortTex)+_Time.y*_WaterSpeed;
                
                o.screenPos = ComputeScreenPos(o.positionCS);
                
                return o;
            }
            half4 frag (Varyings i):SV_Target
            {
                // 屏幕空间UV：用 ComputeScreenPos 的投影坐标更稳（兼容 RenderScale/平台差异）
                float2 screenUV = i.screenPos.xy / i.screenPos.w;

                // 采样场景深度（raw: 0~1）并转眼空间线性深度
                half rawDepth01 = SampleSceneDepth(screenUV);
                half depthScene = LinearEyeDepth(rawDepth01, _ZBufferParams);

                // 水深 = 场景像素深度 - 水面像素深度（相机朝 -Z，所以用 +）
                half depthWater = depthScene + i.positionVS.z;
                depthWater = max(0, depthWater);

                // 水色渐变（0=靠近水面，1=更深处）
                half depth01 = saturate(depthWater / max(0.0001h, _DepthMax));
                half4 WaterColor = lerp(_SurfaceColor, _DeepColor, depth01);

                // 泡沫边缘范围：越浅泡沫越强（把深度差映射成阈值）
                half foamWidth = depthWater * _FoamRange;
                
                //获取水面模型顶点在观察空间下的Z值（可以在顶点着色器中，对其直接进行转化得到顶点观察空间下的坐标）
                
                //2、水的高光

                //3、水的反射

                //4、水的焦散


                //6、水面泡沫
                half foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, i.uv.zw).r;
                //加一个noise来修改Foam纹理的强度,以此控制泡沫多少
                foamTex = pow(abs(foamTex), _FoamNoise);
                ////使用泡沫纹理 和 泡沫范围 比较得到泡沫遮罩，然后制作一个边缘
                half foamMask = step(foamWidth, foamTex);
                half4 foam = foamMask * _FoamColor;

                //5、水下的扭曲 
                //得到扭曲坐标
                half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, i.uv.xy);
                // 扭曲贴图通常是0~1噪声，把它映射到-1~1作为偏移方向；_Distort 作为强度（乘一个小系数避免一扭就穿帮）
                float2 offset = (distortTex.xy * 2.0 - 1.0) * (_Distort * 0.02);
                float2 distortUV = screenUV + offset;

                //先做出深度图，然后用深度图做扭曲
                // 越界直接回退，避免采到屏幕外导致深度/颜色异常
                bool uvOutOfRange = any(distortUV < 0.0) || any(distortUV > 1.0);

                half rawDepthDistort01 = uvOutOfRange ? rawDepth01 : SampleSceneDepth(distortUV);
                //水体对应深度图中的像素在观察空间下的z值
                half depthDistortScene = LinearEyeDepth(rawDepthDistort01, _ZBufferParams);
                half depthDistortWater = depthDistortScene + i.positionVS.z;

                // 关键：水面上方（或扭曲穿帮）不参与扭曲 -> 回退 screenUV
                float2 opaqueUV = (uvOutOfRange || depthDistortWater <= 0) ? screenUV : distortUV;

                //抓屏采样扭曲坐标
                half3 cameraOpaqueTex = SampleSceneColor(opaqueUV);

                half4 c = half4(cameraOpaqueTex, 1);
                // 用抓屏做水下底色，再叠加水色/泡沫
                c.rgb = c.rgb * WaterColor.rgb + foam.rgb;
                //制作半透明效果，只需要修改最终输出的r值，外加blend设置好就行
                c.a = 0.5;
                return c;
            }
            ENDHLSL
        }
    }
    
}