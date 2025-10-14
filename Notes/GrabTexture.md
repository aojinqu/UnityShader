## URP下的抓屏
在BuildIn下，应该使用grabpass

在URP下打开Opaque Texture
  ![GrabTexture-1](./images/URPGrab-1.png)
```C
TEXTURE2D(_CameraOpaqueTexture); 
SAMPLER(sampler_CameraOpaqueTexture); 

...

frag(){
    ...
//Opaque Tex
half4 opaqueMap = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);
return 1-0.3*opaqueMap;//只为了看效果使用该公式
}
                
```
### 降采样
  ![GrabTexture-2](./images/URPGrab-2.png)


## 能量罩

### 交接处高亮
虽然我使用的深度图在frame debugger中是draw procedual，老师的则是draw dynamic，但还是可以照常使用贴图并测试
```C
half4 frag (Varyings i):SV_Target
{
    float2 screenUV = i.positionCS.xy / _ScreenParams.xy;
    half4 depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
    half depth = LinearEyeDepth(depthMap.r, _ZBufferParams);
    return depth;
}
```
右图为反映深度图的贴图
  ![GrabTexture-3](./images/URPGrab-3.png)
### Q
在做深度图的时候，相机的clipping planes非常重要，因为float浮点数有精度问题，只在靠近0的时候特别精确否则会导致相机深度图全部呈现黑色
  ![GrabTexture-4](./images/URPGrab-4.png)

  ![GrabTexture-5](./images/URPGrab-5.png)

在 Unity（尤其是 URP）中，_CameraDepthTexture 保存的是 非线性深度值（通常在 0 到 1 之间）：
绝大多数的“深度分辨率”集中在 摄像机近裁剪面（near plane）附近；

离摄像机越远，深度变化越不明显。

如果你的 near plane 很小（例如 0.1）而 far plane 很大（例如 1000），那么几乎所有的像素深度值都会非常接近 1，看起来几乎全黑。

举例：

    near = 0.1  
    far  = 1000

一个距离为 1 的物体，其线性深度是 0.001，
但经过非线性映射后，它的深度纹理值大约是 0.9；
一个距离为 10 的物体，值大约是 0.99；
而 100 米远的物体接近 1.0。

所以只有调节,缩小 Far Clip Plane（例如从 1000 → 100），增大 Near Clip Plane（例如从 0.1 → 1），才能得到正常的```_CameraDepthTexture```

### Distort扭曲效果
```c=frac(i.uv.y*5+_Time.y);```

作用：首先制作一个类似于sin的循环效果，我们用frac函数来实现，另外通过*5来提高这种效果，最后加上时间流动制造动态效果
