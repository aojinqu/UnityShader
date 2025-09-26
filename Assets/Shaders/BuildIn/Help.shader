Shader "Unlit/Help"
// Simplified VFX Shader with Mask, Texture, Dissolve, Distortion and UV Scrolling
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)]_Cullmode("Cull Mode", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend("Src Blend", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend("Dst Blend", Float) = 10
                
        // Main Texture Section
        [Header(Main Texture)]
        [Toggle]_ScreenAsMain("Screen as Main Texture", Float) = 0
        _MainTex("Main Texture", 2D) = "white" {}
        [HDR]_MainColor("Main Color", Color) = (1,1,1,1)
        _MainAlpha("Main Alpha", Range(0, 1)) = 1
        
        [Header(Main Texture Settings)]
        [Toggle]_MainTexUClamp("U Clamp", Float) = 0
        [Toggle]_MainTexVClamp("V Clamp", Float) = 0

        [Toggle]_MainTexUseR("Use R Channel", Float) = 0
        _MainTex_rotat("Texture Rotation", Range(0, 360)) = 0
        _MainTexRefine("Refine (X:Multiply Y:Power Z:Intensity W:Blend)", Vector) = (1,1,2,0)
        

        [Toggle]_CustomdataMainTexUV("Custom Data UV", Float) = 0
        
        [KeywordEnum(Normal,Polar,Cylinder)] _MainTexUVS("UV Type", Float) = 0
        _MainTex_Uspeed("U Speed", Float) = 0
        _MainTex_Vspeed("V Speed", Float) = 0
                
        // Mask Texture Section
        [Header(Mask Texture)]
        _MaskTex("Mask Texture", 2D) = "white" {}
        _Mask_scale("Mask Scale", Float) = 1
        
        [Header(Mask Settings)]
        _MaskTex_ST("Tiling (X,Y) Offset (Z,W)", Vector) = (1,1,0,0)
        _Mask_rotat("Mask Rotation", Range(0, 360)) = 0
        
        [KeywordEnum(Normal,Polar,Cylinder)] _MaskTexUVS("UV Type", Float) = 0
        _Mask_Uspeed("U Speed", Float) = 0
        _Mask_Vspeed("V Speed", Float) = 0
        
        // Dissolve Section
        [Header(Dissolve Effect)]
        [Toggle]_EnableDissolve("Enable Dissolve", Float) = 0
        _DissloveTex("Dissolve Texture", 2D) = "white" {}
        [HDR]_DIssloveColor("Dissolve Color", Color) = (1,1,1,1)
        
        [Header(Dissolve Settings)]
        //delete
        _Dissolve_rotat("Dissolve Rotation", Range(0, 360)) = 0
        
        _DIssloveFactor("Dissolve Factor", Range(0, 1)) = 0.5
        _DIssloveWide("Dissolve Width", Range(0, 1)) = 0.1
        _DIssloveSoft("Dissolve Softness", Range(0, 1)) = 0.5
        
        [Toggle]_CustomdataDis("Custom Data Dissolve", Float) = 0
        [Toggle]_SoftDissolveMode("Soft Dissolve Mode", Float) = 1
        
        [KeywordEnum(Normal,Polar,Cylinder)] _DissolveTexUVS("UV Type", Float) = 0
        _DisTex_Uspeed("U Speed", Float) = 0
        _DisTex_Vspeed("V Speed", Float) = 0
        
        [Header(Additional Dissolve)]
        [Toggle]_IfDissolvePlus("Enable Additional Dissolve", Float) = 0
        _DissloveTexPlus("Additional Dissolve Tex", 2D) = "black" {}        
        // Distortion Section
        [Header(UV Distortion)]
        [Toggle]_EnableDistort("Enable UV Distortion", Float) = 0
        _DistortTex("Distortion Texture", 2D) = "white" {}
        
        [Header(Distortion Settings)]
        _DistortFactor("Distortion Strength", Range(0, 1)) = 0.03
        [Toggle]_CustomDistort("Custom Data Distortion", Float) = 0
        
        [Header(Distortion Mask)]
        [Toggle]_EnableDistortMask("Enable Distortion Mask", Float) = 0
        _DistortMaskTex("Distortion Mask Tex", 2D) = "white" {}
        
        [Header(Distortion Flow)]
        _DistortTex_Uspeed("U Speed", Float) = 0.3
        _DistortTex_Vspeed("V Speed", Float) = 0.3
        
        [Toggle]_DistortMainTex("Distort Main Texture", Float) = 1
        [Toggle]_DistortDisTex("Distort Dissolve Texture", Float) = 0
        
        // Additional Texture Section


        [Header(Add Texture Settings)]
        [Toggle]_IfAddTex("Enable Add Texture", Float) = 0
        _AddTex("Additional Texture", 2D) = "white" {}
        [HDR]_AddTexColor("Add Color", Color) = (0,0,0,0)
                
        [Toggle]_AddTexAR("Use R Channel", Float) = 0
        _AddTexRo("Add Texture Rotation", Range(0, 360)) = 0
        _AddTexRefine("Refine (X:Multiply Y:Power Z:Intensity W:Blend)", Vector) = (1,1,2,0)
        
        _AddTexBlend("Add Blend", Range(0, 1)) = 0
        [Enum(Alpha,0,Add,1,Multiply,2)]_AddTexBlendMode("Blend Mode", Float) = 0
        
        [KeywordEnum(Normal,Polar,Cylinder)] _AddTexUVS("UV Type", Float) = 0
        _AddTexUspeed("U Speed", Float) = 0
        _AddTexVspeed("V Speed", Float) = 0
        

        
        [HideInInspector] _texcoord("", 2D) = "white" {}
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue"="Transparent" 
            "IgnoreProjector"="True" 
        }
        Blend [_SrcBlend] [_DstBlend]
        Cull [_Cullmode]
        ZWrite Off
    // 添加 GrabPass
        GrabPass { "_ScreenTexture" }        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma shader_feature_local _MAINTEXUVS_NORMAL _MAINTEXUVS_POLAR _MAINTEXUVS_CYLINDER
            #pragma shader_feature_local _MASKTEXUVS_NORMAL _MASKTEXUVS_POLAR _MASKTEXUVS_CYLINDER
            #pragma shader_feature_local _DissolveTEXUVS_NORMAL _DissolveTEXUVS_POLAR _DissolveTEXUVS_CYLINDER
            #pragma shader_feature_local _ADDTEXUVS_NORMAL _ADDTEXUVS_POLAR _ADDTEXUVS_CYLINDER
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float2 uv3 : TEXCOORD2;
                float4 color : COLOR;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float2 uv3 : TEXCOORD2;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float4 screenPos : TEXCOORD3;
            };
            
            // Texture Samplers
            sampler2D _MainTex;
            sampler2D _MaskTex;
            sampler2D _DissloveTex;
            sampler2D _DistortTex;
            sampler2D _DistortMaskTex;
            sampler2D _DissloveTexPlus;
            sampler2D _AddTex;
            sampler2D _ScreenTexture;
            // Main Texture Properties
            float _ScreenAsMain;
            float4 _MainColor;
            float _MainAlpha;
            float _MainTexUClamp;
            float _MainTexVClamp;
            float _MainTexUseR;
            float _MainTex_rotat;
            float4 _MainTexRefine;
            float4 _MainTex_ST;
            float _CustomdataMainTexUV;
            float _MainTex_Uspeed;
            float _MainTex_Vspeed;
            float4 _ScreenTexture_ST;


            // Mask Properties
            float _Mask_scale;
            float4 _MaskTex_ST;
            float _MaskAlphaRA;
            float _Mask_rotat;
            float _Mask_Uspeed;
            float _Mask_Vspeed;
            
            // Dissolve Properties
            float _EnableDissolve;
            float4 _DIssloveColor;
            float4 _DissloveTex_ST;
            float _DissolveAR;
            float _Dissolve_rotat;
            float _DIssloveFactor;
            float _DIssloveWide;
            float _DIssloveSoft;
            float _IfDissolvePlus;
            float4 _DissloveTexPlus_ST;
            float _CustomdataDis;
            float _SoftDissolveMode;
            float _DisTex_Uspeed;
            float _DisTex_Vspeed;

            

            // Distortion Properties
            float _EnableDistort;
            float4 _DistortTex_ST;
            float _DistortTexAR;
            float _DistortFactor;
            float _CustomDistort;
            float _EnableDistortMask;
            float4 _DistortMaskTex_ST;
            float _DistortTex_Uspeed;
            float _DistortTex_Vspeed;
            float _DistortMainTex;
            float _DistortDisTex;
            
            // Additional Texture Properties
            float _IfAddTex;
            float4 _AddTexColor;
            float4 _AddTex_ST;
            float _AddTexAR;
            float _AddTexRo;
            float4 _AddTexRefine;
            float _AddTexBlend;
            float _AddTexBlendMode;
            float _AddTexUspeed;
            float _AddTexVspeed;
            
            
            // UV Rotation Function
            float2 RotateUV(float2 uv, float rotation, float2 center)
            {
                float rad = rotation * 3.14159265359 / 180.0;
                float s = sin(rad);
                float c = cos(rad);
                uv -= center;
                uv = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
                uv += center;
                return uv;
            }
            
            // UV Scrolling Function
            float2 ScrollUV(float2 uv, float uSpeed, float vSpeed)
            {
                float2 scroll = float2(uSpeed, vSpeed) * _Time.y;
                return uv + scroll;
            }
            
            // UV Clamping Function
            float2 ClampUV(float2 uv, float UClampMode,float VClampMode)
            {
                if (UClampMode > 0.5)
                {
                    uv.x=saturate(uv.x);
                }
                if(VClampMode>0.5)
                {
                    uv.y=saturate(uv.y);
                }
                return uv;
            }
            
            // Apply Texture Refine
            float3 ApplyRefine(float3 color, float4 refine)
            {
                float3 base = color * refine.x;
                float3 powered = pow(color, refine.z) * refine.y;
                return lerp(base, powered, refine.w);
            }
            
            // Get UV based on type
            float2 GetUV(float2 baseUV, float4 st, float uvType)
            {
                float2 tiling = st.xy;
                float2 offset = st.zw;
                
                #if defined(_MAINTEXUVS_NORMAL) || defined(_MASKTEXUVS_NORMAL) || defined(_DissolveTEXUVS_NORMAL) || defined(_ADDTEXUVS_NORMAL)
                return baseUV * tiling + offset;
                #elif defined(_MAINTEXUVS_POLAR) || defined(_MASKTEXUVS_POLAR) || defined(_DissolveTEXUVS_POLAR) || defined(_ADDTEXUVS_POLAR)
                float2 centeredUV = baseUV - float2(_CenterU, _CenterV);
                float radius = length(centeredUV) * tiling.x * 2.0;
                float angle = atan2(centeredUV.x, centeredUV.y) * (1.0 / 6.28318530718) * tiling.y;
                return float2(radius, angle) + offset;
                #else
                return baseUV * tiling + offset;
                #endif
            }
            
            // Distortion Function
            float2 ApplyDistortion(float2 uv, float2 distortUV)
            {
                if (_EnableDistort < 0.5) return uv;
                _DistortTexAR=1;
                float2 distort = ScrollUV(distortUV, _DistortTex_Uspeed, _DistortTex_Vspeed);
                float4 distortTex = tex2Dlod(_DistortTex, float4(distort, 0, 0));
                float distortionValue = _DistortTexAR > 0.5 ? distortTex.r : distortTex.a;
                
                // Apply distortion mask if enabled
                if (_EnableDistortMask > 0.5)
                {
                    float4 maskTex = tex2Dlod(_DistortMaskTex, float4(distortUV, 0, 0));
                    distortionValue *= _DistortTexAR > 0.5 ? maskTex.r : maskTex.a;
                }
                
                float2 distortion = (distortionValue * 2.0 - 1.0) * _DistortFactor;
                return uv + distortion;
            }
            
            // Dissolve Function
            float ApplyDissolve(float2 uv, float2 dissolveUV)
            {
                if (_EnableDissolve < 0.5) return 1.0;
                
                float2 dissUV = ScrollUV(dissolveUV, _DisTex_Uspeed, _DisTex_Vspeed);
                dissUV = RotateUV(dissUV, _Dissolve_rotat, float2(0.5, 0.5));
                
                _DissolveAR=1;
                float4 dissolveTex = tex2Dlod(_DissloveTex, float4(dissUV, 0, 0));
                float dissolveValue = _DissolveAR > 0.5 ? dissolveTex.r : dissolveTex.a;
                
                // Additional dissolve texture
                if (_IfDissolvePlus > 0.5)
                {
                    float4 plusTex = tex2Dlod(_DissloveTexPlus, float4(dissUV, 0, 0));
                    dissolveValue = (dissolveValue + (_DissolveAR > 0.5 ? plusTex.r : plusTex.a)) * 0.5;
                }
                
                float threshold = _DIssloveFactor;
                float width = _DIssloveWide;
                float softness = _DIssloveSoft;
                
                if (_SoftDissolveMode > 0.5)
                    return smoothstep(threshold - softness, threshold + softness, dissolveValue);
                else
                    return step(threshold, dissolveValue);
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv2 = v.uv2;
                o.uv3 = v.uv3;
                o.color = v.color;
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // Base UV with custom data support
                float2 baseUV = _CustomdataMainTexUV > 0.5 ? i.uv2 : i.uv;
                baseUV = ClampUV(baseUV, _MainTexUClamp,_MainTexVClamp);
                
                // Apply distortion
                float2 distortUV = GetUV(baseUV, _DistortTex_ST, 0);
                float2 finalUV = baseUV;
                
                if (_DistortMainTex > 0.5)
                    finalUV = ApplyDistortion(baseUV, distortUV);
                
                // Main Texture
                float2 mainUV = GetUV(finalUV, _MainTex_ST, 0);
                mainUV = ScrollUV(mainUV, _MainTex_Uspeed, _MainTex_Vspeed);
                mainUV = RotateUV(mainUV, _MainTex_rotat, float2(0.5, 0.5));
                
                fixed4 mainTex = tex2D(_MainTex, mainUV);
                float mainAlpha = _MainTexUseR > 0.5 ? mainTex.r : mainTex.a;
                float3 mainColor = ApplyRefine(mainTex.rgb, _MainTexRefine);
                
                // Screen as main texture
                if (_ScreenAsMain > 0.5)
                {
                    float2 screenUV = i.screenPos.xy / i.screenPos.w;
                    screenUV = ApplyDistortion(screenUV, distortUV);
                    mainTex = tex2D(_ScreenTexture, screenUV);
                    mainColor = mainTex.rgb;
                    mainAlpha = mainTex.a;
                }
                
                fixed4 finalColor = fixed4(mainColor * _MainColor.rgb, mainAlpha * _MainColor.a);
                
                // Additional Texture
                if (_IfAddTex > 0.5)
                {
                    float2 addUV = GetUV(finalUV, _AddTex_ST, 0);
                    addUV = ScrollUV(addUV, _AddTexUspeed, _AddTexVspeed);
                    addUV = RotateUV(addUV, _AddTexRo, float2(0.5, 0.5));
                    
                    fixed4 addTex = tex2D(_AddTex, addUV);
                    float addAlpha = _AddTexAR > 0.5 ? addTex.r : addTex.a;
                    float3 addColor = ApplyRefine(addTex.rgb, _AddTexRefine) * _AddTexColor.rgb;
                    
                    fixed4 addFinal = fixed4(addColor, addAlpha * _AddTexColor.a);
                    
                    // Blend modes
                    if (_AddTexBlendMode < 0.5) // Alpha blend
                        finalColor = lerp(finalColor, addFinal, _AddTexBlend);
                    else if (_AddTexBlendMode < 1.5) // Add blend
                        finalColor += addFinal * _AddTexBlend;
                    else // Multiply blend
                        finalColor *= addFinal * _AddTexBlend;
                }
                
                // Mask Texture
                float2 maskUV = GetUV(finalUV, _MaskTex_ST, 0);
                maskUV = ScrollUV(maskUV, _Mask_Uspeed, _Mask_Vspeed);
                maskUV = RotateUV(maskUV, _Mask_rotat, float2(0.5, 0.5));

                _MaskAlphaRA=1;

                fixed4 maskTex = tex2D(_MaskTex, maskUV);
                float maskAlpha = _MaskAlphaRA > 0.5 ? maskTex.r : maskTex.a;
                maskAlpha *= _Mask_scale;
                
                // Dissolve Effect
                float2 dissolveUV = _DistortDisTex > 0.5 ? finalUV : baseUV;
                dissolveUV = GetUV(dissolveUV, _DissloveTex_ST, 0);
                float dissolve = ApplyDissolve(dissolveUV, dissolveUV);
                
                // Apply dissolve color
                if (dissolve < 0.5)
                    finalColor.rgb = lerp(finalColor.rgb, _DIssloveColor.rgb, _DIssloveColor.a);
                
                // Final alpha composition
                finalColor.a *= maskAlpha * dissolve * _MainAlpha * i.color.a;
                finalColor.rgb *= i.color.rgb;
                
                return finalColor;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
    CustomEditor "VFXShaderGUI"

}
