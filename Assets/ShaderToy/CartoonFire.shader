//https://www.shadertoy.com/view/lsscWr

Shader "Hidden/CartoonFire"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define  _Step 4 
            float _Cutoff = 0.15; //depth less than this, show black
            sampler2D _MainTex;
            float4 _MainTex_ST;

            float3 mod289(float3 x) 
            {
                return x - floor(x * (1.0 / 289.0)) * 289.0;
            }
            float4 mod289(float4 x) 
            {
                return x - floor(x * (1.0 / 289.0)) * 289.0;
            }

            float4 permute(float4 x) 
            {
                return mod289(((x*34.0)+1.0)*x);
            }

            float4 taylorInvSqrt(float4 r)
            {
                return 1.79284291400159 - 0.85373472095314 * r;
            }
            //ashman noise
            float snoise(float3 v)
            { 
                const float2  C = float2(1.0/6.0, 1.0/3.0) ;
                const float4  D = float4(0.0, 0.5, 1.0, 2.0);

                // First corner
                float3 i  = floor(v + dot(v, C.yyy) );
                float3 x0 =   v - i + dot(i, C.xxx) ;

                // Other corners
                float3 g = step(x0.yzx, x0.xyz);
                float3 l = 1.0 - g;
                float3 i1 = min( g.xyz, l.zxy );
                float3 i2 = max( g.xyz, l.zxy );

                //   x0 = x0 - 0.0 + 0.0 * C.xxx;
                //   x1 = x0 - i1  + 1.0 * C.xxx;
                //   x2 = x0 - i2  + 2.0 * C.xxx;
                //   x3 = x0 - 1.0 + 3.0 * C.xxx;
                float3 x1 = x0 - i1 + C.xxx;
                float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
                float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

                // Permutations
                i = mod289(i); 
                float4 p = permute( permute( permute( 
                            i.z + float4(0.0, i1.z, i2.z, 1.0 ))
                        + i.y + float4(0.0, i1.y, i2.y, 1.0 )) 
                        + i.x + float4(0.0, i1.x, i2.x, 1.0 ));

                // Gradients: 7x7 points over a square, mapped onto an octahedron.
                // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
                float n_ = 0.142857142857; // 1.0/7.0
                float3  ns = n_ * D.wyz - D.xzx;

                float4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

                float4 x_ = floor(j * ns.z);
                float4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

                float4 x = x_ *ns.x + ns.yyyy;
                float4 y = y_ *ns.x + ns.yyyy;
                float4 h = 1.0 - abs(x) - abs(y);

                float4 b0 = float4( x.xy, y.xy );
                float4 b1 = float4( x.zw, y.zw );

                //float4 s0 = float4(lessThan(b0,0.0))*2.0 - 1.0;
                //float4 s1 = float4(lessThan(b1,0.0))*2.0 - 1.0;
                float4 s0 = floor(b0)*2.0 + 1.0;
                float4 s1 = floor(b1)*2.0 + 1.0;
                float4 sh = -step(h, 0);

                float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
                float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

                float3 p0 = float3(a0.xy,h.x);
                float3 p1 = float3(a0.zw,h.y);
                float3 p2 = float3(a1.xy,h.z);
                float3 p3 = float3(a1.zw,h.w);

                //Normalise gradients
                float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
                p0 *= norm.x;
                p1 *= norm.y;
                p2 *= norm.z;
                p3 *= norm.w;

                // Mix final noise value
                float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
                m = m * m;
                return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1), 
                                                dot(p2,x2), dot(p3,x3) ) );
            }
            //将明度色相等转为rgb
            float3 hsv2rgb(float3 c)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }
            //获取整个屏幕的噪波效果
            float getNoise(float2 uv, float t){
                
                //given a uv coord and time - return a noise val in range 0 - 1
                //using ashima noise
                
                //add time to y position to make noise field move upwards
                
                float TRAVEL_SPEED = 1.5;
                
                //octave 1
                float SCALE = 2.0;
                float noise = snoise( float3(uv.x*SCALE ,uv.y*SCALE - t*TRAVEL_SPEED , 0));
                
                //octave 2 - more detail
                SCALE = 6.0;
                noise += snoise( float3(uv.x*SCALE + t,uv.y*SCALE , 0))* 0.2 ;
                
                //move noise into 0 - 1 range    
                noise = (noise/2. + 0.5);
                
                return noise;
                
            }
            //把黑白灰渐变色分离成几个色阶，以生成不同的颜色边缘
            float getDepth(float n)
            {            
                //given a 0-1 value return a depth,                
                //remap remaining non-cutoff region to 0 - 1
                float d = (n - _Cutoff) / (1.0 - _Cutoff);                     
                //step it 色调分离
                d = floor(d*_Step)/_Step;                
                return d;
                
            }


            fixed4 frag (v2f_img i) : SV_Target
            {
            	float2 uv = i.uv;
                uv.x *= 4.0;
                float t = _Time.y * 3.0;    
                float3 col = 0;
                float4 mainTex =tex2D(_MainTex,i.uv);

                //做火焰噪波的关键步骤
                float noise = getNoise(uv, t);
                //shape cutoff to get higher further up the screen
                //模拟出火焰的大体形态（三角形）
                _Cutoff = uv.y;    
                //and at horiz edges
                //_Cutoff += pow(abs(uv.x*0.5 - 1.),1.);   
                
                //火焰形态2
                _Cutoff =pow(uv.y*(1-abs(i.uv.x*2-1)),0.2);
                //对fireGlow加时间还可以模拟忽明忽暗的效果
                fixed4 fireGlow= (1-_Cutoff)*fixed4(1,0.161,0,1);


                //debugview cutoff field
                //return float4(float3(_Cutoff),1.0);   
                
                if (noise < _Cutoff)
                {       
                    //black
                    col = 0;
                }
                else
                {
                    //fire
                    //pow的作用常用于调整明暗对比关系：当n=1时保持原有效果不变，当n<1时会提亮整体亮度
                    float d = pow(getDepth(noise),0.7);   
                    //对卡通火着色   
                    float3 hsv = float3(d*0.17 ,0.8 - d/4., d + 0.8);
                    col = hsv2rgb(hsv);
                }
                col+=mainTex;
                col+=fireGlow;
                return float4(col,1.0); 
            }
            ENDCG
        }
    }
}