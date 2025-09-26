# 序列动画
**关键**
需要理解uv是从左下角开始算的，如图采样(0.9,0.2)得到的是9的粉色

  ![Sequence-1](./images/UVSequence-1.png)

接着需要通过一个线性映射来定位到我们想要的块
1. 块的大小
2. 块的offset
```C
float2 frameScale =float2(1/_Cols,1/_Rows);
//通过序列得到偏移块数
half col = frameIndex % _Cols;
half row = frameIndex / _Cols;
float2 frameOffset=float2(col,row)*frameScale;
return uvInFrame * frameScale + frameOffset;
```