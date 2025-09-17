# 后处理

  ![POST-1](./images/POST-1.png)


### static 关键字
在 C++ 中，需要一个数据对象为整个类而非某个对象服务,同时又力求不破坏类的封装性,即要求此成员隐藏在类的内部，对外不可见时，可将其定义为静态数据。

1. 被 static 修饰的变量属于类变量，可以通过类名.变量名直接引用，而不需要 new 出一个类来
2. 被 static 修饰的方法属于类方法，可以通过类名.方法名直接引用，而不需要 new 出一个类来
   
**总结：通过static关键字标记成员，无需实例化即可直接通过类名访问**

在 C++ 中，静态成员是属于整个类的而不是某个对象，静态成员变量只存储一份供所有对象共用。所以在所有对象中都可以共享它。使用静态成员变量实现多个对象之间的数据共享不会破坏隐藏的原则，保证了安全性还可以节省内存。


**属性**

通过私有字段保护数据，公有属性暴露可控接口。例如：public int Age { get { return age; } set { age = value; } }

封装目的：防止直接修改字段，可在set中添加校验逻辑（如年龄范围限制）。

## 后处理脚本

后期处理是在Unity中对渲染图像应用效果的方法，通过OnRenderImage函数实现，该脚本只能挂在Camera上。

| 知识点 | 核心内容 | 重点| 
| ---| --- | --- | 
|后处理脚本规范 | 介绍如何规范通用的后处理脚本，包括环境准备、脚本添加和效果验证 | 必须使用_MainTex命名接收纹理，否则效果失效|
| Shader属性声明 | 在Shader中声明_MainTex属性以接收渲染纹理，需同时在Properties和CG代码中定义 | 属性名修改会导致纹理传递失败 |
| 剔除与深度设置 | 后处理Shader需配置Cull Off、ZWrite Off、ZTest Always确保正确渲染 | 剔除模式错误会导致画面异常 |
| Unity内置优化| 使用UnityCG.cginc中的appdata_img、v2f_img和vert_img简化顶点处理流程| 结构体字段名需与内置命名一致（如texcoord）| 
| 片段着色器核心| 后处理效果主要在片段着色器中实现（如颜色反转），需基于_MainTex采样处理| 忽略纹理采样会导致输出黑屏

# 后处理实现-黑白阈值后处理效果
需要创建一个后处理效果shader，并在cs脚本中实现拖入shader自动创建材质。

  ![POST-2](./images/POST-2.png)

  记录黑白滤镜效果：
    ![POST-3](./images/POST-3.png)

  实现如下：
```C
//后处理shader
fixed4 frag (v2f_img i) : SV_Target
{
    fixed4 col = tex2D(_MainTex, i.uv);
    //黑白滤镜
    return step(col.r,0.1);//与PS相反。但这样效果更好，所以用了
}
```

```C#
//C#脚本
    [Range(0,1)]public float Value;  //制作滑杆

public Material Mat
{
    get
    {
        if (PostProcessingShader == null){...}
        else if (!PostProcessingShader.isSupported){...}
        if (mat == null)//这段是为了防止每一帧都生成一个新的材质球
        {
            //将shader直接包装成材质球(可以直接用声明material的形式)
            Material _newMat = new Material(PostProcessingShader);
            _newMat.hideFlags = HideFlags.HideAndDontSave;//不保存材质球，用完就删掉
            mat = _newMat;
        }
        return mat;
    }
}
```

最后可以实现利用脚本的滑杆拖动，完成不同的黑白滤镜效果（滑动制作成动画，背景可以像一只眼睛一样闭合，效果非常好！！！）

![POST-4](./images/POST-4.png)
