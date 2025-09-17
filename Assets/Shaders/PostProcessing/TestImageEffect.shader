Shader "Hidden/TestImageEffect"
{
    Properties
    {
        //最重要！！！！一定要把传进来的画面图声明为_MainTex
        _MainTex ("Texture", 2D) = "white" {}
        _Value("Value",float)=0
    }
    SubShader
    {
        // No culling or depth
        Cull Off    //保证面剔除
        ZWrite Off  //保证面片深度不会影响其它深度，影响其它的显示
        ZTest Always //保证自己不会被深度测试拦住

        Pass
        {
            CGPROGRAM
            //#pragma vertex vert
            #pragma vertex vert_img //直接把顶点着色器省掉了
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float _Value;

            fixed4 frag (v2f_img i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return step(_Value,col.r);
            }
            ENDCG
        }
    }
}
