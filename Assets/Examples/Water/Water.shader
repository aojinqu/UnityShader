Shader "aj7/URP/Water"
{
    Properties
    {
        //_SurfaceColor("Surface Color (Near Surface = Darker)", Color) = (0.02, 0.18, 0.35, 0.85)
        //_DeepColor("Deep Color (Deeper = Lighter)", Color) = (0.35, 0.65, 0.85, 0.85)
        _MainParams("Main Params (Atten, Lightness, _, _)", Vector) = (0.03, 1, 0, 0)
        _RampTexture("Ramp Texture",2D)="white"{}

        [Header(Foam)]
        _FoamParams("Foam Params (Range, Speed, Noise, _)", Vector) = (0.8, 0.2, 0.5, 0)
        _FoamTex("Foam Texture",2D)="white"{}
        _FoamColor("Foam Color", Color) = (1,1,1,1)

        [Header(Distort)]
        _NormalTex("Distort Texture",2D)="white"{}
        _DistortParams("Distort Params (Strength, _, _, _)", Vector) = (1, 0, 0, 0)

        [Header(Specular)]
        _SpecularColor("Specular Color",color) = (1,1,1,1)
        _SpecularParams("Specular Params (Distort, Intensity, Smoothness, _)", Vector) = (0.8, 1.5, 8, 0)

        [Header(Reflection)]
        _ReflectionTex("Reflection Texture",Cube)="white"{}

        [Header(Caustic)]
        _CausticTex("Caustic Texture",2D)="white"{}
        _CausticParams("Caustic Params (Speed, Intensity, _, _)", Vector) = (0.2, 3, 0, 0)
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
            //！！！！！！！！！！！！！！！！！！！！！！！！！
            //踩坑！！！！！！！！！！！！！！！！
            //如果Zwrite On，会导致深度图被破坏，无法正确渲染深度
            //一定要关闭深度写入            
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

            CBUFFER_START(UnityPerMaterial)
                float4 _MainParams;     // x=Atten, y=Lightness, z=_, w=_

                float4 _FoamParams;     // x=FoamRange, y=WaterSpeed, z=FoamNoise
                half4 _FoamColor;   

                float4 _DistortParams;  // x=DistortStrength

                float4 _SpecularParams; // x=Distort, y=Intensity, z=Smoothness
                half4 _SpecularColor;

                float4 _CausticParams;  // x=Speed, y=Intensity
            CBUFFER_END

            TEXTURE2D(_CameraDepthTexture); //声明深度纹理
            SAMPLER(sampler_CameraDepthTexture);  //声明深度纹理的采样器
            TEXTURE2D (_CameraOpaqueTexture); //声明不透明纹理
            SAMPLER(sampler_CameraOpaqueTexture); //声明不透明纹理的采样器

            // 水体颜色渐变图（由 Assets/Examples/Water/Water.cs 生成并通过 Shader.SetGlobalTexture("_RampTexture", tex) 赋值）
            // 纹理尺寸为 512x2：y=0（底行）为 Gradient01，y=1（顶行）为 Gradient02
            TEXTURE2D(_RampTexture);
            SAMPLER(sampler_RampTexture);

            TEXTURECUBE(_ReflectionTex); //声明反射纹理
            SAMPLER(sampler_ReflectionTex); //声明反射纹理的采样器

            TEXTURE2D(_CausticTex); //声明焦散纹理
            SAMPLER(sampler_CausticTex); //声明焦散纹理的采样器
            float4 _CausticTex_ST; //焦散纹理的缩放和偏移

            TEXTURE2D(_NormalTex); //声明扭曲纹理
            SAMPLER(sampler_NormalTex); //声明扭曲纹理的采样器
            float4 _NormalTex_ST; //扭曲纹理的缩放和偏移

            TEXTURE2D(_FoamTex);     //主纹理
            SAMPLER(sampler_FoamTex);  //主纹理的采样器
            float4 _FoamTex_ST; //主纹理的缩放和偏移


 
            //顶点着色器的输入（模型的数据信息）
            struct Attributes
            {
                float3 positionOS : POSITION;
                float4 uv : TEXCOORD0; //.xy=foamUV
                float3 normalOS : NORMAL;
            };

            //顶点着色器的输出
            struct Varyings
            {
                float4 positionCS : SV_Position;
                float4 uv : TEXCOORD0; // xy = distortUV,zw = foamUV
                float4 normalUV : TEXCOORD1; 
                float3 positionVS:TEXCOORD2;
                float3 positionWS:TEXCOORD3;
                float4 screenPos:TEXCOORD4;
                float3 normalWS:TEXCOORD5;
            };

            //顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS);
                o.positionVS=TransformWorldToView(o.positionWS);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                //计算得到泡沫纹理采样需要的顶点世界空间下的坐标值的流动效果
                o.uv.zw=o.positionWS.xz*_FoamTex_ST.xy+_Time.y*_FoamParams.y;
                //计算得到水下扭曲纹理的流动UV
                //o.uv.xy=TRANSFORM_TEX(v.uv,_NormalTex)+_Time.y*_WaterSpeed;
                o.normalUV.xy=TRANSFORM_TEX(v.uv,_NormalTex)+_Time.y*_FoamParams.y*float2(1,1);
                o.normalUV.zw=TRANSFORM_TEX(v.uv,_NormalTex)+_Time.y*_FoamParams.y*float2(-1.07,1.13);

                o.screenPos = ComputeScreenPos(o.positionCS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                return o;
            }
            half4 frag (Varyings i):SV_Target
            {
                
                //屏幕空间下的UV坐标
                float2 screenUV = i.positionCS.xy / _ScreenParams.xy;

                //水的深度（越靠近水面颜色越深，反之越浅，越远越浅）
                half depthTex=SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,screenUV).r;
                half atten = _MainParams.x;
                //水体对应深度图中的像素在观察空间下的z值
                half depthScene = LinearEyeDepth(depthTex, _ZBufferParams);//从相机到场景表面的距离/深度”，是正值
                half depthWater =(depthScene+i.positionVS.z)*atten;

                //需求：越靠近水面颜色越深；越往下越浅
                half tDepth = saturate(depthWater);
                half foamRange = depthWater * _FoamParams.x;

                // 基础水色：两个 Color 插值（tDepth=0 贴近水面，1 更深）
                //half4 WaterColor = lerp(_SurfaceColor, _DeepColor, tDepth);

                // Ramp 额外控制：用 0.25/0.75 取 texel center，避免双线性过滤时跨行串色
                half4 ramp01 = SAMPLE_TEXTURE2D(_RampTexture, sampler_RampTexture, float2(tDepth, 0.25));
                half4 ramp02 = SAMPLE_TEXTURE2D(_RampTexture, sampler_RampTexture, float2(tDepth, 0.75));
                
                //获取水面模型顶点在观察空间下的Z值（可以在顶点着色器中，对其直接进行转化得到顶点观察空间下的坐标）
            


                //5、水下的扭曲 
                //得到扭曲坐标
                half4 normalTex1 = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.normalUV.xy);
                half4 normalTex2 = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.normalUV.zw);
                half4 normalTex = normalTex1*normalTex2;
                //这里只用到Tex1
                float2 distortUV=screenUV+normalTex1.xy*_DistortParams.x;

                //先做出深度图，然后用深度图做扭曲
                half depthDistortTex=SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,distortUV).r;                
                //水体对应深度图中的像素在观察空间下的z值
                half depthDistortScene = LinearEyeDepth(depthDistortTex, _ZBufferParams);
                half depthDistortWater =depthDistortScene+i.positionVS.z;
                //如果深度小于0，则使用抓屏颜色，否则使用扭曲颜色
                half2 opaqueUV=distortUV;
                if(depthDistortWater<0)//说明在水面上方
                    opaqueUV=screenUV;

                //抓屏采样扭曲坐标
                half4 cameraOpaqueTex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,opaqueUV);


                //4、水的焦散
                float4 depthVS=1;
                depthVS.xy=i.positionVS.xy*depthDistortScene/-i.positionVS.z;
                depthVS.z=depthDistortScene;
                float3 depthWS=mul(unity_CameraToWorld,depthVS).xyz;
                //制作焦散
                float2 causticUV1=depthWS.xz*_CausticTex_ST.xy +depthWS.y*0.2+_CausticParams.x*_Time.y;
                half4 causticTex1=SAMPLE_TEXTURE2D(_CausticTex,sampler_CausticTex,causticUV1);
                float2 causticUV2=depthWS.xz*_CausticTex_ST.xy+depthWS.y*0.1+_CausticParams.x*_Time.y*float2(-1.07,1.13);
                half4 causticTex2=SAMPLE_TEXTURE2D(_CausticTex,sampler_CausticTex,causticUV2);
                //为什么用取小？
                half4 causticTex=min(causticTex1,causticTex2);
                half4 caustic=causticTex*_CausticParams.y;



                //6、水面泡沫
                half4 foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, i.uv.zw);
                //加一个noise来修改Foam纹理的强度,以此控制泡沫多少
                foamTex = pow(abs(foamTex), _FoamParams.z);
                ////使用泡沫纹理 和 泡沫范围 比较得到泡沫遮罩，然后制作一个边缘
                half foamMask = step(foamRange, foamTex.r);
                half4 foam = foamMask * _FoamColor;



                //2、水的高光
                //Specular=SpecularColor*Ks*pow(max(0,dot(N,H)),shineness)
                half3 N = normalize(i.normalWS);
                N=lerp(N,normalTex.xyz,_SpecularParams.x);
                //URP获取平行主灯
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 V = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
                half3 H = normalize(L+V);
                half4 specular = _SpecularColor * _SpecularParams.y * pow(saturate(dot(N,H)),_SpecularParams.z);


                //3、水的反射
                half3 reflectionUV = reflect(-V,N);
                half4 reflectionTex = SAMPLE_TEXTURECUBE(_ReflectionTex,sampler_ReflectionTex,reflectionUV);
                half fresnel = pow(1-saturate(dot(N,V)),3);
                reflectionTex = reflectionTex*fresnel;

                half4 c = half4(0,0,0,1);  
                // Ramp 的常见用法：ramp02 用于“染色/吸收”水下抓屏，ramp01 提供额外表层色调
                half lightness = _MainParams.y;
                c =ramp01*lightness;
                c +=specular*reflectionTex;
                c +=foam;
                return c;
                c +=reflectionTex;
                c +=caustic;
                // 预乘 Alpha 混合：Blend One OneMinusSrcAlpha
                // 要求输出的 rgb 已经乘过 alpha，否则容易出现偏亮/发灰、颜色不受控等问题
                c.a = saturate(ramp02.a);
                c.rgb *= c.a;
                return c;
            }
            ENDHLSL
        }
    }
    
}