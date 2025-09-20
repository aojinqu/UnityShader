Shader "aj7/Unlit/Ghost"
{
    Properties
    {
        _FresnelColor("Fresnel Color",Color)=(0,0,0,0)
        _Fresnel("Fade(X),Intensity(Y),TOP(Z)",vector)=(4,1,0,0)
        _Offset("Offset",Range(-1,1))=0
        _Animation("Repeat(XZ),Intensity(YW)",vector)=(5,0.05,5,0.1)
    }
    //第一个SubShader写URP通用的渲染管线
    //第二个写BuildIn。如果第一个匹配不上就会走到第二个。
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline" 
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        BLEND One One 

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Fresnel;
            half4 _FresnelColor;
            half _Offset;
            half4 _Animation;
            CBUFFER_END
            struct Attributes  //appata
            {
                float4 vertex : POSITION;
                float3 normalOS:NORMAL;  //OS: Object Space
            };

            struct Varyings    //vertex
            {
                float4 vertex : SV_POSITION;
                float3 worldPosWS:TEXCOORD1;
                float3 normalWS:TEXCOORD2;  //WS:World Space
                float3 ObjectPosOS:TEXCOORD3;  
            };

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.ObjectPosOS=v.vertex;
                //顶点偏移动画
                v.vertex.x+=sin((v.vertex.y+_Time.y)*_Animation.x)*_Animation.y;  //里面xz调节动画速度，外面yw调节动画移动幅度
                v.vertex.z+=sin((v.vertex.y+_Time.y)*_Animation.z)*_Animation.w;  

                o.normalWS=TransformObjectToWorldNormal (v.normalOS);                
                o.worldPosWS =TransformObjectToWorld(v.vertex);
                o.vertex = TransformObjectToHClip(v.vertex);
                
                return o;
            } 

            half4 frag (Varyings i) : SV_Target
            {
                half4 c;
                half3 N = normalize(i.normalWS);   //要重新做归一化，因为经过了插值
                //顶点到相机的方向！！做点积的话要到统一顶点！！
                half3 V =normalize(_WorldSpaceCameraPos-i.worldPosWS);
                //为什么要max(0,)?因为物体的背面也有法线，这个时候视线看过去和它的点积是负数，我们不希望有这种情况，因为从背后看是看不到模型的，所以统一限定为1
                //为什么要dot(N,V)?因为菲涅尔，人的视线越垂直于物体，看到的光就越少，越平行于物体看到的光就越多
                half dotNV=1-saturate(dot(N,V));
                //加大这种程度，就需要使得(0,1)区间内的y值中间小两头高，所以采用指数函数
                half4 fresnel=pow(dotNV,_Fresnel.x)*_Fresnel.y*_FresnelColor;
                
                //创建从上到下的黑白遮罩
                half mask = saturate( i.ObjectPosOS.y+i.ObjectPosOS.z+_Offset);//凡是乘等于c的变量，都要注意它的正负性和是否范围(0,1)

                //c=fresnel*mask+mask*0.1*_FresnelColor;//加上后面的之后上面的模型和下面的模型的菲涅尔效果也是不同的

                fresnel =lerp(fresnel,_FresnelColor*mask,mask*_Fresnel.z);
                c=fresnel*mask;
                return c;
            }
            ENDHLSL
        }
    }

        //BuildIn
    SubShader
    {
        Tags 
        {            
            "RenderType"="Transparent"
            "Queue"="Transparent" 
        }
        LOD 100
        BLEND One One
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            half4 _Fresnel;
            half4 _FresnelColor;
            half _Offset;
            half4 _Animation;
            
            struct appdata
            {
                float2 uv:TEXCOORD0;
                float4 vertexOS : POSITION;
                float3 normalOS:NORMAL;  //OS: Object Space
            };

            struct v2f
            {
                float2 uv:TEXCOORD0;
                float4 vertexOS : SV_POSITION;
                float3 worldPosWS:TEXCOORD1;
                float3 normalWS:TEXCOORD2;  //WS:World Space
                float3 ObjectPosOS:TEXCOORD3;
            };

            v2f vert (appdata v)
            {
                v2f o;

                o.ObjectPosOS=v.vertexOS;
                //顶点偏移动画
                v.vertexOS.x+=sin((v.vertexOS.y+_Time.y)*_Animation.x)*_Animation.y;  //里面xz调节动画速度，外面yw调节动画移动幅度
                v.vertexOS.z+=sin((v.vertexOS.y+_Time.y)*_Animation.z)*_Animation.w;  

                o.normalWS=UnityObjectToWorldNormal(v.normalOS);                
                o.worldPosWS =mul(unity_ObjectToWorld,v.vertexOS);

                o.vertexOS = UnityObjectToClipPos(v.vertexOS);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            { 
                half4 c;
                half3 N = normalize(i.normalWS);    
                half3 V =normalize(_WorldSpaceCameraPos-i.worldPosWS); 
                half dotNV=1-saturate(dot(N,V));
 
                half4 fresnel=pow(dotNV,_Fresnel.x)*_Fresnel.y*_FresnelColor;                
                //创建从上到下的黑白遮罩
                half mask = saturate( i.ObjectPosOS.y+i.ObjectPosOS.z+_Offset); 
 
                fresnel =lerp(fresnel,_FresnelColor*mask,mask*_Fresnel.z);
                c=fresnel*mask;
                return c;
            }
            ENDCG
        }
    }
}
