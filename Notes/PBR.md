# PBR

  ![PBR-1](./images/PBR-1.png)

### PBS

### 反射探针采样

见shader参考大全Lighting不分
``` C
    //反射探针中当前激活的CubeMap存储在unity_SpecCube0当中，必须要用UNITY_SAMPLE_TEXCUBE进行采样，然后需要对其进行解码
    half4 cubemap_reflect = UNITY_SAMPLE_TEXCUBE (unity_SpecCube0, R);
    half3 skyColor = DecodeHDR (cubemap_reflect, unity_SpecCube0_HDR);
    return fixed4(skyColor, 1.0);
```
效果如下图，左下角为采样，右上为反射探针
  ![PBR-2](./images/PBR-2.png)


### 双向反射分布函数BRDF