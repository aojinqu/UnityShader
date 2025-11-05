# GI

![GI-1](./images/GI-1.png)

**烘焙和实时全局光照是只对静态物体有效**

实现GI有两种方案Realtime GI和Baked GI，对应的最终实现的形式为Dynamic Lightmap动态光照贴图和Lightmap光照贴图。

### 光照模式(Lighting Modes)
选中灯光，在Inspector面板中，你可以指定光源的光照模式，这个光照模式定义了该光源的预期用途。

![GI-3](./images/GI-3.png)

**Mixed Lighting**
>典型应用一：灯光的间接光部分被烘焙到lightmap中，烘焙完成后，该光源还能继续参与实时光照计算，以提供材质的法线高光效果。 

>典型应用二：将灯光对静态物体产生的阴影烘焙到单独的lightmap中，这种lightmap叫做ShadowMask，在运行时，根据ShadowMask，对动态物体产生的实时阴影能够与烘焙阴影更好地混合。

场景中的所有混合灯光使用相同的混合光照模式(Mixed Lighting Mode)，需要在Lighting面板Mixed Lighting选项的Lighting Mode中进行选择，有Subtractive、Baked Indirect、ShadowMask、DistanceShadowMask四种模式。

**Subtractive模式**
- 完全烘焙直接光和间接光
- 动态物体仅接收实时阴影
- 特点：关闭灯光后场景光照不变
- 
会将Mixed灯光的直接照明、间接照明、阴影信息全部烘焙到Lightmap中去，这一点跟Baked GI是一样。

Subtractive模式也是四种混合光照模式中，唯一会将直接照明烘焙到lightmap的模式。

```C#
    //BakedGI为例
    #if defined(LIGHTMAP_ON) 
    o.lightmapUV.xy = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw; // 计算光照贴图的UV坐标
    #endif
```
**Baked Indirect模式：**
- 仅烘焙间接光照
- 直接光保持实时计算，Mixed灯光会继续为所有物体提供实时直接照明和实时阴影
- 适用场景：需要动态光源但保留GI效果的场景
 

**Shadowmask模式：**
- 直接光和间接光分开烘焙
- 阴影单独存储在遮罩贴图
- 灯光强度变化影响阴影强度

工程设置：在Quality Settings中配置Shadowmask Mode
距离遮挡掩模 

在ShadowMask模式下：
静态GameObjects通过ShadowMask接收来自其他静态GameObjects的阴影。他们也会从动态GameObjects中获得实时阴影，但是只有阴影距离(Shadow Distance)内的阴影。

**Distance Shadowmask：**
- 近处使用实时阴影,远处使用烘焙阴影
- 通过Shadow Distance参数控制过渡范围
- 性能优化：平衡视觉效果与性能消耗
  
我们在烘焙的时候，动态物体收到的光照影响是不能直接烘焙进 bakedLightMap，用实时光照就会产生强大的额外开销。所以光照探针，是对lightMap的补充，

###  光照探针
光探测器（光照探针 Light Probe）存储有关场景中照明的“烘焙”信息。

光照贴图存储有关光线照射场景中表面的光照信息，但光照探测器存储有关光线穿过场景中空白空间的信息。

说白了，光照贴图只存储 mesh 表面的光影信息；而光照探针，存储空白空间的光影信息，包括直接光和间接光（反射光），是对光照贴图的补充

**光照探针的简单应用**
对于光照比较复杂的静态屋内场景，一般都需要用光照探针烘焙。
https://zhuanlan.zhihu.com/p/347708855

光照探针，是对lightMap的补充，我们在烘焙的时候，动态物体收到的光照影响是不能直接烘焙进bakedLightMap，用实时光照就会产生强大的额外开销。而反射探针能够将动态物体的实时光照烘焙进GI中，这样就可以取代实时光照而减少渲染的开销：
### 光照探针组 Light Probe Group
光照探针组就是一组光照探针，默认是一个立方体，4*2一组，共八个光照探针组成。

可以通过编辑，增加或删除光照探针，也可以随意移动光照探针位置。

![GI-5](./images/GI-5.png)


### 间接光的产生Meta Pass

关于Unity里自发光材质的烘焙，一个是要加上Meta Pass，一个是要设置材质的Lightmap Flags设置为BakedEmissive

实现间接光反弹（物体对其他物体产生间接光照效果）

* 核心方法：通过添加**Meta Pass**实现间接光计算

* Pass特性：
仅在烘焙时使用，不影响实时渲染
负责提取光照贴图、GI(发射、反照率)信息

![GI-6](./images/GI-6.png)
实操控制物体自发光的间接光照：打开debug模式，Lightmap Flags可以控制各种模式下的间接光，设置为None则不产生间接光

## 光照模型
光照模型，是用来模拟物体表面如何被光线照亮的。
在开始之前，我们需要知道，一个完整的光照模型通常由三个部分组成：
1. **环境光 Ambient**：模拟从周围环境（如墙壁、其他物体）反弹过来的间接光。它是一个常量，确保物体没有直接被光源照射的部分也不是完全漆黑的。

2. **漫反射 Diffuse**：模拟光线撞击物体表面后，向各个方向均匀散射的现象。这是物体本身呈现的颜色，它的强度与光线方向和表面法线的夹角有关。

3. **镜面高光 Specular**：模拟光线在光滑表面上的反射，形成亮斑（高光）。它的强度与观察者的位置密切相关。
   
Lambert模型只包含前两部分，而Blinn-Phong模型则包含全部三部分。 这就是它们最根本的区别。

### Lmabert光照
Lambert模型描述的是一个理想的漫反射体，比如粉笔、粗糙的墙面。这种表面会将入射光均匀地散射到所有方向。

**核心思想**：
漫反射的强度 只取决于光线入射角，与观察者的位置无关。

    光线垂直照射时（入射角为0°），最亮。

    光线擦着表面照射时（入射角接近90°），最暗。

    当光线从背面照射时（入射角大于90°），不接受光照。

漫反射光的强度计算公式为：

```Diffuse = Kd * (LightColor) * max(dot(N, L), 0) ```   

- Kd：物体的漫反射系数，其实就是物体的颜色（一个RGB向量）。

- LightColor：光源的颜色和强度。

- N：物体表面该点的单位法线向量。

- L：从该点指向光源的单位向量。

- dot(N, L)：计算法线向量N和光线向量L的点积。点积的几何意义是衡量两个向量的夹角余弦值（cosθ）。
  
**总结：**

优点：计算非常简单，性能开销小。

缺点：无法表现镜面高光，因此物体看起来是“哑光”的，缺乏光泽感。

适用：表现粗糙、无光泽的物体，如木头、石头、粉笔等。

### Blinn-Phong 光照模型
Blinn-Phong模型是对早期Phong模型的改进。在Lambert的漫反射基础上，增加一个镜面高光项。这个高光的强度不仅取决于光线方向，还强烈依赖于观察者的视角。

Blinn-Phong的巧妙之处在于引入了一个“**半程向量**”来计算高光，这比原始Phong模型（直接计算反射向量和视线向量的夹角）计算效率更高，且视觉效果更好。

```FinalColor = Ambient + Diffuse + Specular```

FinalColor = Ambient + Diffuse + Specular

```Ambient = Ka * (LightColor)``` （Ka是环境光系数，通常是个很小的值）

```Diffuse = Kd * (LightColor) * max(dot(N, L), 0) ```   和Lambert模型的计算公式完全一样。

```Specular = Ks * (LightColor) * pow(max(dot(N, H), 0), Shininess)```

- Ks：物体的镜面反射系数，通常是一个浅灰色或白色，表示高光的颜色。

- N：物体表面该点的单位法线向量。

- H：半程向量，是光线向量L和视线向量V的角平分线方向的单位向量。H = normalize(L + V)。

- L：从该点指向光源的单位向量。

- V：从该点指向观察者（相机）的单位向量。

- dot(N, H)：计算法线N和半程向量H的点积。这个值越大，说明视线方向越接近光线的完美反射方向，高光就越强。
  
- pow(..., Shininess)：pow是幂函数。Shininess是光泽度系数（也叫反光度）。

**总结：**

优点：计算比原始Phong模型更高效（半程向量的计算比反射向量简单）。

能产生逼真的高光效果，让物体看起来有光泽。
在PBR（基于物理的渲染）流行之前，它是绝对的主流。