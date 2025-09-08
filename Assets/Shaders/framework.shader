Shader "aj7/Framework"  // 定义shader名字
{
    Properties
    {
        _Color("Color",Color)=(1,1,1,1)  //可以隐藏
        _Value("Intensity",float)=1
    }
    SubShader //一个shader中有多个subshader，系统会一个个往下遍历找，不支持的会跳过
    {
        pass //一个pass就是一次渲染，每个shader都要有一个pass块
        {
            CGPROGRAM

            #pragma vertex vert //编译指令，连接顶点和片段着色器
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _Color;      //声明必须和属性名一样，不然对应不上
            float _Value;
            //顶点输入：位置、UV
            struct appdata  //约定叫appdata结构体
            {
                float4 vertex:POSITION;
                float4 color:COLOR0;    //direct3D中用0
            };

            struct v2f 
            {
                float4 pos:SV_POSITION;
                float3 VertexPos:TEXCOORD0;
            };

            v2f vert(appdata v)//顶点着色器
            {
                v2f o=(v2f)0; //定义需要初始化，不然容易报错 ;注意是定义部分加括号
                o.pos=UnityObjectToClipPos(v.vertex);  //顶点着色器中必做这步，把模型空间转换到裁剪空间
                o.VertexPos=v.vertex.xyz;
                return o;
            }
            float4 frag(v2f i):SV_Target //sv_t是输入到屏幕的颜色
            {
                float4 tmp=float4(1,1,1,1);
                tmp=float4(i.VertexPos,1.0);
                return tmp;
            }
            ENDCG
        }

    }

    //CustomEditor ""//自定义修改器
    //Fallback ""//备胎，适用于subshader都不支持的情况
}















// Shader "Unlit/NewUnlitShader"
// {
//     Properties
//     {
//         _MainTex ("Texture", 2D) = "white" {}
//     }
//     SubShader
//     {
//         Tags { "RenderType"="Opaque" }
//         LOD 100

//         Pass
//         {
//             CGPROGRAM
//             #pragma vertex vert
//             #pragma fragment frag
//             // make fog work
//             #pragma multi_compile_fog

//             #include "UnityCG.cginc"

//             struct appdata
//             {
//                 float4 vertex : POSITION;
//                 float2 uv : TEXCOORD0;
//             };

//             struct v2f
//             {
//                 float2 uv : TEXCOORD0;
//                 UNITY_FOG_COORDS(1)
//                 float4 vertex : SV_POSITION;
//             };

//             sampler2D _MainTex;
//             float4 _MainTex_ST;

//             v2f vert (appdata v)
//             {
//                 v2f o;
//                 o.vertex = UnityObjectToClipPos(v.vertex);
//                 o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//                 UNITY_TRANSFER_FOG(o,o.vertex);
//                 return o;
//             }

//             fixed4 frag (v2f i) : SV_Target
//             {
//                 // sample the texture
//                 fixed4 col = tex2D(_MainTex, i.uv);
//                 // apply fog
//                 UNITY_APPLY_FOG(i.fogCoord, col);
//                 return col;
//             }
//             ENDCG
//         }
//     }
// }
