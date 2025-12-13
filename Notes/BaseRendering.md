# 渲染基础


## BLEND 混合

### 基本概念

混合（Blending）决定了当前片元（正在渲染的像素）如何与帧缓冲区（Frame Buffer）中已经存在的像素颜色进行结合。

人话：Blend 控制当前像素与已绘制像素的混合方式。

**关键术语**：
- **源颜色（Source）**：当前Shader计算出的颜色，用 `Src` 表示
- **目标颜色（Destination）**：帧缓冲区中已存在的颜色，用 `Dst` 表示
- **混合公式**：`FinalColor = SrcFactor × SrcColor + DstFactor × DstColor`

### 常用混合因子

| 因子 | 说明 | 值 |
|------|------|-----|
| `One` | 1.0 | 完全不透明 |
| `Zero` | 0.0 | 完全透明 |
| `SrcColor` | 源颜色的RGB | 源颜色值 |
| `SrcAlpha` | 源颜色的Alpha | 源Alpha值 |
| `DstColor` | 目标颜色的RGB | 目标颜色值 |
| `DstAlpha` | 目标颜色的Alpha | 目标Alpha值 |
| `OneMinusSrcAlpha` | 1 - 源Alpha | 反向Alpha |
| `OneMinusDstAlpha` | 1 - 目标Alpha | 反向目标Alpha |

### 混合模式详解

| 混合模式	| 语法	| 效果	| 用途 | 
|----------|-------|------|------|
| 不混合	| Blend Off	| 直接覆盖	| 不透明物体	|
| 标准透明	| Blend SrcAlpha OneMinusSrcAlpha	| 半透明	| 玻璃、水| 
| 加色混合	| Blend One One	| 发光叠加	| 光效、X光| 
| 乘法混合	| Blend DstColor Zero	| 变暗	| 阴影、遮罩| 
| 加法混合	| Blend One OneMinusSrcColor	| 柔和发光| 	柔和光效| 


## ZTest

ZTest 决定是否通过深度测试，控制像素是否被绘制。

💡 深度测试模式说明 (Z-Test/Depth Test Modes)

| 模式 (Mode) | 含义 (Meaning) | 描述 (Description) |
| :---: | :---: | :--- |
| **Less** | 小于 $(<)$ | 深度更小才绘制（默认，表示物体**更近**时绘制） |
| **LEqual** | 小于等于 $(\le)$ | 深度更小或相等时绘制（默认值） |
| **Equal** | 等于 $(=)$ | 深度相等时才绘制 |
| **Greater** | 大于 $(>)$ | 深度更大才绘制（表示物体**更远**时绘制） |
| **GEqual** | 大于等于 $(\ge)$ | 深度更大或相等时绘制 |
| **NotEqual** | 不等于 $(\ne)$ | 深度不相等时才绘制 |
| **Always** | 总是 | 总是绘制（**忽略**深度测试结果） |
| **Never** | 从不 | 从不绘制 |


## ZWrite

ZWrite 决定是否将当前像素的深度值写入深度缓冲区。

1. 选项
On：写入深度（默认）

Off：不写入深度

2. ⚙️ 深度测试 (ZTest) 与深度写入 (ZWrite) 效果用途

## 4. 组合使用示例

| ZTest | ZWrite | 效果 | 用途 |
| :---: | :---: | :---: | :---: |
| Less | On | 正常渲染 | 不透明物体 |
| Less | Off | 半透明渲染 | 透明物体 |
| Greater | Off | 只渲染被遮挡部分 | X光效果 |
| Always | Off | 总是绘制，不影响深度 | UI、后处理 |

## 模板测试 (Stencil Test)

### 基本概念

模板测试(Stencil Test)通过比较模板缓冲区中的值与预设参考值来决定是否更新像素颜色值。模板缓冲区是一个8位的缓冲区，每个像素可以存储0-255的值。

**关键点**：
- 模板缓冲区与颜色缓冲区、深度缓冲区是平行的概念
- 模板测试代码应写在 `Pass` 外部（在 `SubShader` 或 `Pass` 的标签区域）
- 模板测试发生在深度测试之前

### 核心公式

```
(Ref & ReadMask) Comp (StencilBufferValue & ReadMask)
```

**参数说明**：
- `Ref`：参考值（Reference Value），通常是0-255的整数
- `ReadMask`：读取掩码，用于过滤比较的位
- `Comp`：比较函数（如 Equal, Greater, Less 等）
- `StencilBufferValue`：模板缓冲区中当前像素的值

### 常用属性

| 属性 | 说明 | 常用值 |
|------|------|--------|
| `Ref` | 参考值 | 0-255 |
| `Comp` | 比较函数 | Always, Equal, Greater, Less 等 |
| `Pass` | 测试通过时的操作 | Keep, Replace, IncrementSaturate 等 |
| `Fail` | 测试失败时的操作 | Keep, Zero 等 |
| `ZFail` | 深度测试失败时的操作 | Keep, Replace 等 |
| `ReadMask` | 读取掩码 | 255（默认，读取所有位） |
| `WriteMask` | 写入掩码 | 255（默认，写入所有位） |

### 实战示例：圆形遮罩

**需求**：实现一个圆形遮罩效果，只显示圆形区域内的内容。

**实现思路**：
1. 第一个Pass：绘制遮罩形状，写入模板缓冲区（Ref=1）
2. 第二个Pass：绘制被遮罩的内容，只在模板值为1的区域显示

**Shader代码示例**：

```hlsl
Shader "Custom/CircleMask"
{
    SubShader
    {
        Tags { "Queue"="Transparent" }
        
        // Pass 1: 写入模板缓冲区（绘制遮罩形状）
        Pass
        {
            Stencil
            {
                Ref 1
                Comp Always
                Pass Replace
            }
            
            ColorMask 0  // 不写入颜色，只写入模板
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            struct appdata {
                float4 vertex : POSITION;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
            };
            
            v2f vert(appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {
                // 计算圆形遮罩
                float2 center = float2(0.5, 0.5);
                float2 uv = i.pos.xy / _ScreenParams.xy;
                float dist = distance(uv, center);
                clip(0.5 - dist);  // 只保留圆形区域
                return fixed4(0,0,0,0);
            }
            ENDCG
        }
        
        // Pass 2: 使用模板测试绘制内容
        Pass
        {
            Stencil
            {
                Ref 1
                Comp Equal  // 只在模板值为1的区域渲染
            }
            
            // 正常的渲染代码...
        }
    }
}
```

### 参数暴露示例

在Shader中暴露模板参数给材质面板：

```hlsl
Properties
{
    [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Compare", Float) = 8
    [Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Float) = 0
    _StencilRef ("Stencil Reference", Range(0, 255)) = 1
}

SubShader
{
    Stencil
    {
        Ref [_StencilRef]
        Comp [_StencilComp]
        Pass [_StencilOp]
    }
}
```

---

## RenderType Tag

### 基本概念

`RenderType` 是Unity渲染系统的标签，用于告诉Unity引擎这个Shader的用途和分类。**它不是给GPU的指令，而是给Unity引擎的元数据**。

### 常用RenderType值

| RenderType | 说明 | 使用场景 |
|------------|------|----------|
| `Opaque` | 不透明物体 | 默认材质、实体物体 |
| `Transparent` | 透明物体 | 玻璃、水、UI |
| `TransparentCutout` | 透明裁剪 | 树叶、栅栏（Alpha Test） |
| `Background` | 背景 | 天空盒 |
| `Overlay` | 覆盖层 | UI、特效 |

### 为什么需要RenderType？

1. **渲染排序**：Unity会根据RenderType对物体进行排序
   - `Transparent` 物体会被从后往前排序
   - `Opaque` 物体会被从前往后排序（深度测试优化）

2. **相机设置影响**：
   - 影响是否写入深度缓冲区
   - 影响是否进行深度测试
   - 影响渲染队列（Queue）

3. **后处理兼容性**：
   - 某些后处理效果只作用于特定RenderType
   - 例如：Bloom效果通常只处理 `Transparent` 物体

### 完整示例

```hlsl
Shader "Custom/TransparentShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
    }
    
    SubShader
    {
        // 标签：告诉Unity这是透明物体
        Tags { 
            "Queue"="Transparent"           // 渲染队列：透明队列
            "RenderType"="Transparent"      // 渲染类型：透明
            "IgnoreProjector"="True"        // 忽略投影器
        }
        
        // GPU指令：定义混合方式
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off
        
        Pass
        {
            // Shader代码...
        }
    }
}
```

### Blend 与 RenderType 的关系

| 特性 | `Blend One One` | `RenderType="Transparent"` |
|------|-----------------|---------------------------|
| **作用对象** | GPU（硬件层面） | Unity引擎（软件层面） |
| **功能** | 定义颜色混合的数学公式 | 定义物体的渲染分类和排序 |
| **必要性** | 必须要有混合设置才能混合 | 强烈推荐，但不是绝对必须 |
| **影响结果** | 直接决定视觉效果 | 影响渲染顺序和性能优化 |
| **位置** | 写在SubShader或Pass中 | 写在Tags中 |
| **示例** | `Blend One One` | `Tags { "RenderType"="Transparent" }` |

### 最佳实践

1. **透明物体**：
   ```hlsl
   Tags { "Queue"="Transparent" "RenderType"="Transparent" }
   Blend SrcAlpha OneMinusSrcAlpha
   ```

2. **发光效果**：
   ```hlsl
   Tags { "Queue"="Transparent" "RenderType"="Transparent" }
   Blend One One
   ```

3. **不透明物体**：
   ```hlsl
   Tags { "Queue"="Geometry" "RenderType"="Opaque" }
   // 不需要Blend（默认不混合）
   ```

4. **透明裁剪（Alpha Test）**：
   ```hlsl
   Tags { "Queue"="AlphaTest" "RenderType"="TransparentCutout" }
   AlphaTest Greater 0.5
   ```

## 前向渲染(ForwardBase)

- **ForwardBase Pass**（`LightMode = ForwardBase`）：负责把模型画到屏幕上（采样贴图、算光照/阴影衰减、输出颜色）。


    ForwardBase 是 Unity 前向渲染的“基础光照 Pass”。它通常会处理：
    - 主方向光（或最重要的一盏光）
    - 环境光/球谐光照（如果你用到）
    - 以及把阴影结果乘到颜色上（如 `UNITY_LIGHT_ATTENUATION(atten, ...)` 得到的 atten）

    简单理解：ForwardBase = 屏幕上的主渲染 Pass。


- **ShadowCaster Pass**（`LightMode = ShadowCaster`）：负责在灯光生成阴影贴图时，把模型画进阴影图（深度图）里（输出的是深度/遮挡信息，不是颜色）。在做真实阴影时一定要有这个pass。

    ShadowCaster Pass 会在渲染阴影贴图时被调用。
    它通常只做：
    - 根据顶点位置/法线生成“投影到光源视角下”的深度
    - 写入阴影图（或相关缓冲）