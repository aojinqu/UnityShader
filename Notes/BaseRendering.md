# 渲染基础


### 模板测试

- 基本概念：模板测试(Stencil Test)通过比较模板缓冲区中的值与预设参考值来决定是否更新像素颜色值

- 缓冲区关系：模板缓冲区与颜色缓冲区是平行概念，模板测试代码应写在Pass外部

- 核心公式：`(Ref&ReadMask)Comp(StencilBufferValue&ReadMask)`

|重点| 方法|
|--- | --- |
|遮罩实战实现 | 通过Stencil Ref=1与模板缓冲区值比较实现圆形遮罩|
Shader参数暴露 | 使用[Enum]声明StencilOp和CompareFunction| 

### BLEND 混合
混合决定了当前片元（正在渲染的像素）如何与帧缓冲区（Frame Buffer）中已经存在的像素颜色进行结合。

- 源颜色（Source）：当前Shader计算出的颜色

- 目标颜色（Destination）：帧缓冲区中已存在的颜色
  
#### 例：Blend One One 加法混合

```Blend One One```为最终颜色 = (源颜色 × 1) + (目标颜色 × 1)

```Blend One One```多用于半透明效果,特别适合火焰、灯光、魔法效果等需要"发光"的半透明物体。

新的半透明颜色会与背景颜色相加，产生亮度叠加的效果，并且多个加法混合的物体渲染顺序不影响最终结果

#### 例：Blend SrcAlpha OneMinusSrcAlpha alpha混合

公式: 最终颜色 = 源颜色 × 源Alpha + 目标颜色 × (1 - 源Alpha)

实现真正的半透明效果，基于Alpha通道，适用 玻璃、水、透明塑料、UI元素

需要从后往前排序渲染，所以性能消耗比加法混合更大。

### RenderType Tag
```RenderType=Transparent```区分```Blend One One```

这是给Unity的渲染系统看的标签，不是给GPU的指令。它告诉Unity："这个Shader是用来渲染透明物体的"。

Unity会基于这个标签对透明物体进行从后往前的排序，确保正确的混合顺序。会影响相机的渲染设置，如是否写入深度等


| 特性     | BLEND One One          | RenderType="Transparent" |
| -------- | ---------------------- | ------------------------ |
| 作用对象 | GPU（硬件层面）        | Unity（引擎层面）        |
| 功能     | 定义颜色混合的数学公式 | 定义物体的渲染分类和排序 |
| 必要性   | 必须要有混合设置       | 强烈推荐，但不是绝对必须 |
| 影响结果 | 直接决定视觉效果       | 影响渲染顺序和性能       |

