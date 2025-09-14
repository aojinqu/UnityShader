#ifndef MYPHYSICALLYBASESRENDERINGCGINC
#define MYPHYSICALLYBASESRENDERINGCGINC
#endif

inline float3 Unity_SafeNormalize1(float3 inVec)
{
        //max用于放负值
    float dp3 = max(0.001f, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}


// Note: Disney diffuse must be multiply by diffuseAlbedo / PI. This is done outside of this function.
half DisneyDiffuse1(half NdotV, half NdotL, half LdotH, half perceptualRoughness)
{
    half fd90 = 0.5 + 2 * LdotH * LdotH * perceptualRoughness;
    // Two schlick fresnel term
    half lightScatter   = (1 + (fd90 - 1) * Pow5(1 - NdotL));
    half viewScatter    = (1 + (fd90 - 1) * Pow5(1 - NdotV));

    return lightScatter * viewScatter;
}

half4 BRDF1_Unity_PBS1 (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
    float3 normal, float3 viewDir,
    UnityLight light, UnityIndirect gi)
{
    //感性粗糙度  1-smoothness
    float perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
    //H= L +V,得到半角向量
    float3 halfDir = Unity_SafeNormalize1 (float3(light.dir) + viewDir);
//法线与视线的点积本不该有负数，但可能发生在投影与法线映射时，可以通过某些方式来修正，但是会产生额外的指令运算，替代方案采用abs的形式，只是正确性略微降低
// NdotV should not be negative for visible pixels, but it can happen due to perspective projection and normal mapping
// In this case normal should be modified to become valid (i.e facing camera) and not cause weird artifacts.
// but this operation adds few ALU and users may not want it. Alternative is to simply take the abs of NdotV (less correct but works too).
// Following define allow to control this. Set it to 0 if ALU is critical on your platform.
// This correction is interesting for GGX with SmithJoint visibility function because artifacts are more visible in this case due to highlight edge of rough surface
// Edit: Disable this code by default for now as it is not compatible with two sided lighting used in SpeedTree.
#define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0

#if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
    // The amount we shift the normal toward the view vector is defined by the dot product.
    half shiftAmount = dot(normal, viewDir);
    normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;
    // A re-normalization should be applied here but as the shift is small we don't do it to save ALU.
    //normal = normalize(normal);

    float nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
#else
    half nv = abs(dot(normal, viewDir));    // This abs allow to limit artifact
#endif

    float nl = saturate(dot(normal, light.dir));
    float nh = saturate(dot(normal, halfDir));

    half lv = saturate(dot(light.dir, viewDir));
    half lh = saturate(dot(light.dir, halfDir));

    // Diffuse term 迪士尼原则的漫反射
    //按照迪士尼原则，本来应该除以π
    //但会导致颜色比旧的材质更暗，并且从引擎层面看，被标记为不重要的灯光在SH时也会被除以π
    half diffuseTerm = DisneyDiffuse1(nv, nl, lh, perceptualRoughness) * nl;

    // Specular term
    // HACK: theoretically we should divide diffuseTerm by Pi and not multiply specularTerm!
    // BUT 1) that will make shader look significantly darker than Legacy ones
    // and 2) on engine side "Non-important" lights have to be divided by Pi too in cases when they are injected into ambient SH
    float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
#if UNITY_BRDF_GGX
    // GGX with roughtness to 0 would mean no specular at all, using max(roughness, 0.002) here to match HDrenderloop roughtness remapping.
    roughness = max(roughness, 0.002);
    float V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
    float D = GGXTerm (nh, roughness);
#else
    // Legacy
    half V = SmithBeckmannVisibilityTerm (nl, nv, roughness);
    half D = NDFBlinnPhongNormalizedTerm (nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
#endif

    float specularTerm = V*D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

#   ifdef UNITY_COLORSPACE_GAMMA
        specularTerm = sqrt(max(1e-4h, specularTerm));
#   endif

    // specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
    specularTerm = max(0, specularTerm * nl);
#if defined(_SPECULARHIGHLIGHTS_OFF)
    specularTerm = 0.0;
#endif

    // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
    half surfaceReduction;
#   ifdef UNITY_COLORSPACE_GAMMA
        surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#   else
        surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
#   endif

    // To provide true Lambert lighting, we need to be able to kill specular completely.
    specularTerm *= any(specColor) ? 1.0 : 0.0;

    half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
    //迪士尼
    //diffclor：s.abedo 基础颜色，也是漫反射
    //gi.diffuse:间接漫反射光
      //specularColor :镜面反射
    half3 diffuse = diffColor * (gi.diffuse + light.color * diffuseTerm);
    half3 specularColor = specularTerm * light.color * FresnelTerm (specColor, lh);
    half3 ibl = surfaceReduction * gi.specular * FresnelLerp (specColor, grazingTerm, nv);
    half3 color = diffuse + specularColor+ibl;
    return half4(diffColor, 1); 
}

// Default BRDF to use:
#if !defined (UNITY_BRDF_PBS1) // allow to explicitly override BRDF in custom shader
    // still add safe net for low shader models, otherwise we might end up with shaders failing to compile
    #if SHADER_TARGET < 30 || defined(SHADER_TARGET_SURFACE_ANALYSIS) // only need "something" for surface shader analysis pass; pick the cheap one
        #define UNITY_BRDF_PBS1 BRDF3_Unity_PBS
    #elif defined(UNITY_PBS_USE_BRDF3)
        #define UNITY_BRDF_PBS1 BRDF3_Unity_PBS
    #elif defined(UNITY_PBS_USE_BRDF2)
        #define UNITY_BRDF_PBS1 BRDF2_Unity_PBS
    #elif defined(UNITY_PBS_USE_BRDF1)
        #define UNITY_BRDF_PBS1 BRDF1_Unity_PBS1
    #else
        #error something broke in auto-choosing BRDF
    #endif
#endif

inline half OneMinusReflectivityFromMetallic1(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline half3 DiffuseAndSpecularFromMetallic1 (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
    //算高光颜色，当金属度为0，选非金属颜色作为高光颜色
    //前者是绝缘体的通用反射颜色，迪士尼用0.04来表示
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    //算1-反射率(漫反射的反射率)
    oneMinusReflectivity = OneMinusReflectivityFromMetallic1(metallic);
    return albedo * oneMinusReflectivity;
}


inline half4 LightingStandard1 (SurfaceOutputStandard s, float3 viewDir, UnityGI gi)
{
    s.Normal = normalize(s.Normal);

    half oneMinusReflectivity;
    half3 specColor;
    s.Albedo = DiffuseAndSpecularFromMetallic1 (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

    // shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
    // this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
    //开启透明模式进行的alpha相关计算

    //具体的BRDF
    //abeldo:物体表面的基础颜色
    //specular:镜面反射颜色
    //漫反射率：1-镜面反射率
    //smoothness:物体表面的光滑度
    //norlma:物体表面的法线
    //viewDIR:视线方向
    //gi.light:直接光信息
    //gi.indirect:间接光信息
    half outputAlpha;
    s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);
    //具体的BRDF
    half4 c = UNITY_BRDF_PBS1 (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
    c.a = outputAlpha;
    return c;
}

half3 Unity_GlossyEnvironment1 (UNITY_ARGS_TEXCUBE(tex), half4 hdr, Unity_GlossyEnvironmentData glossIn)
{
    half perceptualRoughness = glossIn.roughness /* perceptualRoughness */ ;

// TODO: CAUTION: remap from Morten may work only with offline convolution, see impact with runtime convolution!
// For now disabled
#if 0
    float m = PerceptualRoughnessToRoughness(perceptualRoughness); // m is the real roughness parameter
    const float fEps = 1.192092896e-07F;        // smallest such that 1.0+FLT_EPSILON != 1.0  (+1e-4h is NOT good here. is visibly very wrong)
    float n =  (2.0/max(fEps, m*m))-2.0;        // remap to spec power. See eq. 21 in --> https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf

    n /= 4;                                     // remap from n_dot_h formulatino to n_dot_r. See section "Pre-convolved Cube Maps vs Path Tracers" --> https://s3.amazonaws.com/docs.knaldtech.com/knald/1.0.0/lys_power_drops.html

    perceptualRoughness = pow( 2/(n+2), 0.25);      // remap back to square root of real roughness (0.25 include both the sqrt root of the conversion and sqrt for going from roughness to perceptualRoughness)
#else
    // MM: came up with a surprisingly close approximation to what the #if 0'ed out code above does.
    perceptualRoughness = perceptualRoughness*(1.7 - 0.7*perceptualRoughness);
#endif

    //rgbm =粗糙度x6
    half mip = perceptualRoughnessToMipmapLevel(perceptualRoughness);
    half3 R = glossIn.reflUVW;
    half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, R, mip);

    return DecodeHDR(rgbm, hdr);
}


inline half3 UnityGI_IndirectSpecular1(UnityGIInput data, half occlusion, Unity_GlossyEnvironmentData glossIn)
{
    half3 specular;
    //如果开起来boxprojection 反射探针会跟着变化
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
        // we will tweak reflUVW in glossIn directly (as we pass it to Unity_GlossyEnvironment twice for probe0 and probe1), so keep original to pass into BoxProjectedCubemapDirection
        half3 originalReflUVW = glossIn.reflUVW;
        glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[0], data.boxMin[0], data.boxMax[0]);
    #endif

    //若材质面板上不要reflection
    #ifdef _GLOSSYREFLECTIONS_OFF
        specular = unity_IndirectSpecColor.rgb;
    #else
        half3 env0 = Unity_GlossyEnvironment1 (UNITY_PASS_TEXCUBE(unity_SpecCube0), data.probeHDR[0], glossIn);
        #ifdef UNITY_SPECCUBE_BLENDING
            const float kBlendFactor = 0.99999;
            float blendLerp = data.boxMin[0].w;
            UNITY_BRANCH
            if (blendLerp < kBlendFactor)
            {
                #ifdef UNITY_SPECCUBE_BOX_PROJECTION
                    glossIn.reflUVW = BoxProjectedCubemapDirection (originalReflUVW, data.worldPos, data.probePosition[1], data.boxMin[1], data.boxMax[1]);
                #endif

                half3 env1 = Unity_GlossyEnvironment (UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), data.probeHDR[1], glossIn);
                specular = lerp(env1, env0, blendLerp);
            }
            else
            {
                specular = env0;
            }
        #else
            specular = env0;
        #endif
    #endif

    return specular * occlusion;
}

//GI计算
inline UnityGI UnityGlobalIllumination1 (UnityGIInput data, half occlusion, half3 normalWorld, Unity_GlossyEnvironmentData glossIn)
{
    //声明返回结构UnityGI
    UnityGI o_gi = UnityGI_Base(data, occlusion, normalWorld);
    o_gi.indirect.specular = UnityGI_IndirectSpecular1(data, occlusion, glossIn);
    return o_gi;
}

float SmoothnessToPerceptualRoughness1(float smoothness)
{
    return (1 - smoothness);
}

Unity_GlossyEnvironmentData UnityGlossyEnvironmentSetup1(half Smoothness, half3 worldViewDir, half3 Normal, half3 fresnel0)
{
    //声明返回的结构体g
    Unity_GlossyEnvironmentData g;
    //粗糙度
    g.roughness /* perceptualRoughness */   = SmoothnessToPerceptualRoughness1(Smoothness);
    //反射球的采样坐标
    g.reflUVW   = reflect(-worldViewDir, Normal);

    return g;
}

//PBR光照模型的GI计算
inline void LightingStandard_GI1 (
    SurfaceOutputStandard s,
    UnityGIInput data,
    inout UnityGI gi)
{
    //若为延迟渲染pass 且开启了延迟渲染反射探针的话
    #if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
        gi = UnityGlobalIllumination1(data, s.Occlusion, s.Normal);
    #else
        //g表示GI中的反射准备数据（如反射贴图）
        Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup1(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
        //进行GI计算并返回输出gi
        gi = UnityGlobalIllumination1(data, s.Occlusion, s.Normal, g);
    #endif
}