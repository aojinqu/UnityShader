# Water

## 深度
水的深度（越靠近水面颜色越深，反之越浅，越远越浅）

我们使用URP深度图来做。

首先在URP 资源下，打开depth和opaque图。

！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！

写在最前面：做透明水面（尤其还要采样场景深度做水深差）时，**ZWrite Off 基本是必选项！！！！！！！！！**

！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！

因为水是 Transparent（透明队列），它的正确渲染逻辑是：
- 先画不透明物体（写深度）
- 再画透明水面（只做颜色混合，不写深度）
如果水面 `ZWrite On`，它会把“水面这层”写进深度缓冲，后果是：
- 水面之后要渲染的像素/物体（尤其是透明/后处理/某些排序情况下的物体）会被 深度测试挡住
- 要靠 `_CameraDepthTexture` 做“水下渐变”，但被水面深度挡掉的那些像素看不到/不参与，视觉上就会变成**一片黑、没有渐变或断层**

更直白一句：**透明水要“看得到后面的东西”，就不能占用深度**。


```C#
half depthTex=SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,screenUV);

//水体对应深度图中的像素在观察空间下的z值
half depthScene = Linear01Depth(depthTex, _ZBufferParams);
half depthWater =depthScene+i.positionVS.z;
```

### Linear01Depth和LinearEyeDepth的区别

**核心概念**

深度纹理（_CameraDepthTexture）存储的是非线性深度值（通常在 0-1 之间），精度分布不均匀：
- 近处精度高，远处精度低
- 大部分深度值集中在近裁剪面附近

这两个函数用于将非线性深度转换为线性深度，便于计算。


**Linear01Depth**

```C#
half depthScene = Linear01Depth(depthTex, _ZBufferParams);
```
返回值：0-1 范围的线性深度
- 0 = 相机位置（近裁剪面）
- 1 = 远裁剪面

用途：
- 用于归一化计算
- 用于颜色插值（如深度雾效）
- 用于深度比较（0-1 范围便于比较）

**LinearEyeDepth**

返回值：**观察空间**下的线性深度值（单位：距离单位，不是 0-1）
- 返回的是从相机到物体的实际距离
- 范围取决于相机的近/远裁剪面设置

```C#
half depthTex = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
half depthEye = LinearEyeDepth(depthTex, _ZBufferParams);
// depthEye 范围: [Near, Far]（例如 0.1 到 1000）
// 返回的是实际距离值
```

用途：
- 需要实际距离时使用
- 计算水面深度差
- 基于距离的效果（如距离衰减）

效果如下：

![Water-1](./images/Water-1.png)

## 泡沫(卡通)

```C#
//制作一个边缘
half foamMask =step(foamRange,foamTex);
half4 foam = foamMask * _FoamColor;
return foam + WaterColor;
```

- `foamRange =depthWater * _FoamRange;`：把“水深差”映射成一个阈值（越深阈值越大）
- `foamTex`：泡沫噪声（0~1）
- `pow(foamTex, foamNoise)`：调噪声分布（让亮点更集中/更稀疏）
- `step(foamRange, foamTex)`：硬阈值，噪声超过阈值就出泡沫（1），否则没有（0），这一步是关键

这会在水-物体交界附近形成“碎边线”


![Water-2](./images/Water-2.png)

![Water-3](./images/Water-3.png)


## 扭曲
定义一个扰度值，控制扭曲水下的扭曲程度
屏幕UV 和 法线纹理扭曲之间线性插值
原理：先取一张扭曲叠图，得到扭曲uv。然后用抓屏来采样这个坐标，使得采样扭曲。
```C#
    half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex,sampler_DistortTex,i.uv.xy);
    float2 distortUV=lerp(screenUV,distortTex.xy,_Distort);
```

## Q&A
1. `half foamTex=SAMPLE_TEXTURE2D(_FoamTex,sampler_FoamTex,i.position.xy);`和`half foamTex=SAMPLE_TEXTURE2D(_FoamTex,sampler_FoamTex,i.uv);`的区别是什么?

`i.position.xy`采样

**区别本质是：用“世界坐标当 UV” vs 用“模型 UV 当 UV”，会导致泡沫纹理“贴在世界上”还是“贴在模型上”。**
效果：
- 泡沫图案像“铺在地面/水面世界里”，物体移动、缩放水面模型时，泡沫**不会跟着模型 UV 拉伸**，更像真实的“世界空间噪声”

- 但因为世界坐标不是 0~1，通常要自己做 **缩放/平铺**（比如乘一个 tiling，再 frac），否则会采样得很乱/频率不受控
(需要通过Tiling控制泡沫大小和移动速度)
`i.uv`采样

效果：

- 泡沫严格跟着模型 UV 走：模型缩放/UV 拉伸会导致泡沫一起被拉伸或压缩
- 如果水面是一个 plane 且 UV 规整，这种方式简单直观；但换成不规则网格容易变形


2. **我的问题是抓屏怎么只抓水面下的部分，而不是把整个屏幕都抓了？**

URP 的 _CameraOpaqueTexture（或 SampleSceneColor）是相机在某个时刻把整张屏幕渲染结果拷贝出来的纹理，它不可能只生成“水面下的区域”。

能做的是：采样时只让“水面下方的像素”使用抓屏颜色，水面上方不使用（或直接返回水面自身颜色）——也就是“只在水面下显示抓屏”。