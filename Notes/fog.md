# 雾效的混合公式 
### 原理
**基本公式：最终颜色 = lerp(物体颜色，雾效颜色，雾效混合因子)**

物体颜色：
```unity_FogColor```

- 混合因子：
  * 包含物体离视角的距离（决定雾效强度）
  * 包含雾的浓度（决定雾效的浓淡程度）
- 实现原理：通过差值计算在物体颜色和雾效颜色之间进行混合
  

#### 线性雾效衰减 

公式：
$$ fogFactor=\frac{end-z}{end-start} $$

参数说明：
- start：雾开始的位置
- end：雾结束的位置
- z：物体的深度值（这里指物体到摄像机的距离）

特点：衰减呈直线变化，在Unity中可调节start和end参数

#### 指数雾效衰减 
1) 普通指数衰减：
公式：
$$ fogFactor=e^{-density·z}$$
参数：仅需调节density（雾的浓度）
特点：衰减曲线呈指数下降

2) 平方指数衰减：
公式：
$$ fogFactor=e^{-(density·z)^2}$$
特点：衰减曲线更陡峭
区别：指数衰减不需要设置start和end参数，通过浓度控制整体效果

## 打开雾效
网上unity雾效教程说勾选 Windows->Rendering->LightingSettings->OtherSettings->Fog 即可开启unity 默认雾效，但unity更新后，需要在Windows->Rendering->LightingSettings->Environment->OtherSettings->Fog 中才能找到

![fog-1](./images/fog-1.png)

## 实现方法
需要实现远处的物体颜色与雾色集合，变得模糊。
共有三种
``` C#
  struct v2f
  {
      float2 uv : TEXCOORD0;

      float4 vertex : SV_POSITION;
      float3 worldPos : TEXCOORD2;
      //方法一：自定义雾效插值器
      float fogFactor: TEXCOORD3;
      //方法二：等于开启雾效时定义一个float类型的变量fogCoord
      //UNITY_FOG_COORDS(1)
      //方法三
      //无需额外定义雾效插值器，但需要将worldPos定义为float4，将计算出来的fogFactor存入worldPos.w中

  };
```
以下为第一种自定义的写法，用于展示原理
``` C#
  v2f vert (appdata v)
  {
      v2f o;
      o.vertex = UnityObjectToClipPos(v.vertex);
      o.uv = TRANSFORM_TEX(v.uv, _MainTex);
      o.worldPos = mul(unity_ObjectToWorld,v.vertex);
      float z= length(o.worldPos-_WorldSpaceCameraPos);//计算物体位置到摄像机的距离
          // x = density / sqrt(ln(2)), useful for Exp2 mode
          // y = density / ln(2), useful for Exp mode
          // z = -1/(end-start), useful for Linear mode
          // w = end/(end-start), useful for Linear mode
          //float4 unity_FogParams;以上为其4个参数含义，可以用于获取end start的值
      #if defined(FOG_LINEAR)
          o.fogFactor= saturate( z*unity_FogParams.z + unity_FogParams.w);//不能直接-z！！！！
      #elif defined(FOG_EXP)   
          o.fogFactor=exp2(-z*unity_FogParams.y);
      #elif defined(FOG_EXP2)
          
          o.fogFactor=exp2(-pow(z*unity_FogParams.x,2));
      #endif
      //Unity内部雾效方法
      //UNITY_TRANSFER_FOG(o,o.vertex);
      return o;
  }
```
对物体颜色和雾色做线性插值，是三种雾效共同的做法
```    c#
  fixed4 frag (v2f i) : SV_Target
  {
    // sample the texture
    fixed4 c =1;

    #if defined (FOG_LINEAR)||(FOG_EXP)||(FOG_EXP2)  
        c=lerp( unity_FogColor,c,i.fogFactor);
    #endif

    // apply fog unity 内部方法
    //UNITY_APPLY_FOG(i.fogCoord, c);
    return c;
  }
```