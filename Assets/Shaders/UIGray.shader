Shader "aj7/UIGray"
{
    Properties
    {
        _Ref("Stencil Ref",int)=0
        [PerRendererData]_MainTex("MainTex",2D) = "white"{}
        _Color("Color",color)=(1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8.000000
        _Stencil ("Stencil ID", Float) = 0.000000
        _StencilOp ("Stencil Operation", Float) = 0.000000
        _StencilWriteMask ("Stencil Write Mask", Float) = 255.000000
        _StencilReadMask ("Stencil Read Mask", Float) = 255.000000
        _ColorMask ("Color Mask", Float) = 15.000000

        [Toggle]_GrayEnabled("Gray Enabled",int)=1

    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha //需要保证和UI的blend模式一致，可以通过frame debugger查询
        Cull Off
        ColorMask [_ColorMask]

        //使用模板测试实现遮罩
        Stencil
        {
            Ref [_Stencil]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
            Comp [_StencilComp]
            Pass [_StencilOp]
        }    

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ UNITY_UI_CLIP_RECT
            #pragma multi_compile _ _GRAYENABLED_ON

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            sampler2D _MainTex;
            float4 _ClipRect;


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color: COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color: COLOR;
                float4 vertex : TEXCOORD1;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv=v.uv;
                o.color=v.color;
                o.vertex=v.vertex;
                return o;       
            }
 
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = tex2D(_MainTex, i.uv);  
                c *= i.color;      

                #if _GRAYENABLED_ON
                //c.rgb=c.rrr; 使用单通道赋值，会变灰，但根据r不一样而灰色也不一样。
                    c.rgb=c.r;
                //去色公式，数字为常数.不会随rgb三个通道的变化而变化。
                    c.rgb=c.r*0.22+c.g*0.707+c.b*0.071;
                //内部函数，原理同去色公式。
                    c.rgb=Luminance(c.rgb);
                #endif

                #if UNITY_UI_CLIP_RECT
                    //此处有三种方法，从基础判断；到函数实现简化；再到使用内部函数
                    //return step(_ClipRect.x,i.vertex.x)*step(i.vertex.x,_ClipRect.z)*step(_ClipRect.y,i.vertex.y)*step(i.vertex.y,_ClipRect.w);                    
                    c.a*=UnityGet2DClipping(i.vertex,_ClipRect);

                #endif
                

                return c;
            }
            ENDCG
        }
    }
}
