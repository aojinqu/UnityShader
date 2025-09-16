# C# 脚本相关

注意点
1. 内部名称与外部名称必须相同
   外部名称：test.cs
   内部名称（类名）：public class test: MonoBehaviour{}  
   冒号后表示继承，test为派生类，MonoBehaviour为基类
   **Unity中所有可挂载脚本必须直接或间接继承MonoBehaviour**，因为提供了Unity引擎调用的生命周期方法

- Start(): 在首次帧更新前调用
- Update(): 每帧调用一次
- OnCollision系列: 处理碰撞事件
- OnGUI(): 处理GUI绘制