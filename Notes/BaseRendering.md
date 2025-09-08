# 渲染基础


### 模板测试

- 基本概念：模板测试(Stencil Test)通过比较模板缓冲区中的值与预设参考值来决定是否更新像素颜色值

- 缓冲区关系：模板缓冲区与颜色缓冲区是平行概念，模板测试代码应写在Pass外部

- 核心公式：`(Ref&ReadMask)Comp(StencilBufferValue&ReadMask)`

|重点| 方法|
|--- | --- |
|遮罩实战实现 | 通过Stencil Ref=1与模板缓冲区值比较实现圆形遮罩|
Shader参数暴露 | 使用[Enum]声明StencilOp和CompareFunction| 