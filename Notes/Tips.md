# Tips
1. 有时候会需要做一张从上到下的黑白渐变贴图，或者从左到右，可以考虑使用模型的本地坐标。
    并且可以扩展到用```i.ObjectPosWS.y+i.ObjectPosWS.z;```，能够得到3D上斜切效果。
      ![BaseRendering-3](./images/BaseRendering-1.png)

2. 想做循环动画，会需要用到三角函数
   
   例如```sin(_Time.y)```可以做直线效果。
   
   如果需要曲线运动，则需要做扰动，可以考虑用自身的坐标来扰动，这样模型的各个部分就自动有了不同的动画```v.vertex.x+=sin(v.vertexOS.y+_Time.y)```。(详见URP.md)