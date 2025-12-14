# PBR

  ![PBR-1](./images/PBR-1.png)

### PBS

### 反射探针采样

见shader参考大全Lighting部分
``` C
    //反射探针中当前激活的CubeMap存储在unity_SpecCube0当中，必须要用UNITY_SAMPLE_TEXCUBE进行采样，然后需要对其进行解码
    half4 cubemap_reflect = UNITY_SAMPLE_TEXCUBE (unity_SpecCube0, R);
    half3 skyColor = DecodeHDR (cubemap_reflect, unity_SpecCube0_HDR);
    return fixed4(skyColor, 1.0);
```
效果如下图，左下角为采样，右上为反射探针
  ![PBR-2](./images/PBR-2.png)


### 双向反射分布函数BRDF
  ![BRDF-1](./images/BRDF-1.png)


实操
做PBR之前先转移到线性空间

  ![BRDF-2](./images/BRDF-2.png)

  ![BRDF-3](./images/BRDF-3.png)

由于上图的原因，Linear空间下会自动对sRGB做解码操作，先移除gamma校正，使用完数据后重新gamma校正。所以对于线性空间下的贴图需要实现勾选下图中的sRBG才能获得正确的结果

  ![BRDF-4](./images/BRDF-4.png)

  ![BRDF-5](./images/BRDF-5.png)

``` C

    #if UNITY_BRDF_GGX
    // GGX with roughtness to 0 would mean no specular at all, using max(roughness, 0.002) here to match HDrenderloop roughtness remapping.
    roughness = max(roughness, 0.002);
    float V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
    float D = GGXTerm (nh, roughness);
    #endif
    //镜面反射中D和V的计算。乘以π是因为上面漫反射该除以的π美除，所以式子两边同时乘以π。D为法线分布函数
    float specularTerm = V*D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later
    
    //镜面反射DFG/4coslcov
    //F为FresnelTerm，specularTerm为DF
    half3 specularColor = specularTerm * light.color * FresnelTerm (specColor, lh);
```


D项
  ![BRDF-6](./images/BRDF-6.png)

  ![BRDF-8](./images/BRDF-8.png)


F项
  ![BRDF-7](./images/BRDF-7.png)

### BRDF的优势
可以直接在lighting-environment中修改cubemap等参数，shader会自己做适配，不需要自己再修改内部参数。

如下图，在custom定制模式下，使用一张p2的cubemap环境贴图，可以改变物体表面的ibl效果，不用修改任何shader参数
  ![BRDF-9](./images/BRDF-9.png)
  ![BRDF-10](./images/BRDF-10.png)
