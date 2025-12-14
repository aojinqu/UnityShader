# UGUI

UGUI 是 Unity 传统的 UI 系统，核心命名空间是 UnityEngine.UI。它是“用 Canvas 统一渲染的一套 UI 渲染管线”。

- Canvas：UGUI 的“渲染根节点/画布”。Canvas 下的 UI 会被收集、批处理并以 UI 的方式渲染。
- RectTransform：UI 专用的 Transform（锚点、对齐、拉伸等布局能力）。
- Graphic：所有可绘制 UI 的基类（Image、RawImage、Text、TMP_Text 的渲染层逻辑都类似）。
- Image：最常用的 UI 图片组件，使用 Sprite，默认 shader 是 UI/Default。
- 事件系统：EventSystem + GraphicRaycaster 实现点击、拖拽、滑动等交互。

![UGUI-3](./images/UGUI-3.png)

### 案例：棋盘格shader制作

理论：
![UGUI-2](./images/UGUI-2.png)

![UGUI-1](./images/UGUI-1.png)


### 代码控制button，toggle与slider
在开始时添加Listener响应事件，并将脚本拖入到canvas面板上，然后添加Button和Toggle。
toggle则需要传入一个bool作为参数表示开关是否被按下：

```C
    public Button button01;
    public Toggle toggle01;
    public Slider slider01;

    void Start()
    {
        button01.onClick.AddListener(OnButton01);
        toggle01.onValueChanged.AddListener(OnToggle01);
        slider01.onValueChanged.AddListener(OnSlider01);

    }
    void OnButton01()
    {
        ...
    }
    void OnToggle01(bool isOn)
    {
        ...
    }
    void OnSlider01(float value)
    {
       ...
    }
```

### UI调用并修改其他脚本参数
在Slider的listener函数中加入character的事件响应，需要用getComponent，而script被添加进角色后，就属于这个角色的component了：

```character.GetComponent<RotateSelf>();```

### UI修改shader