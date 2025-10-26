Shader "aj7/RaymarchSDF_URP"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        _Resolution("Resolution", Vector) = (512,512,0,0)
        _Mouse("Mouse", Vector) = (0,0,0,0)
        _TimeParams("TimeParams", Vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            // URP-compatible unlit-style target
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _Resolution; // xy = width,height
            float4 _Mouse;      // xy = mouse pixel pos (or normalized), zw unused
            float4 _TimeParams; // Unity _Time: x = t/20, y = t, z = t*2, w = t*3  (we'll use .y)

            Varyings vert(Attributes v) {
                Varyings o;
                o.position = TransformObjectToHClip(v.position);
                o.uv = v.uv;
                return o;
            }

            // --------------------------
            // GLSL -> HLSL helpers & SDFs
            // --------------------------
            #define ZERO (0)

            // convenience macros
            float dot2(float2 v) { return dot(v,v); }
            float dot2(float3 v) { return dot(v,v); }

            float sdPlane(float3 p) { return p.y; }
            float sdSphere(float3 p, float s) { return length(p) - s; }

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
            }

            // ... (for brevity: include only functions we actually use from original map)
            // But to keep parity, I'll include the most used ones. If you want them all,
            // we can paste the rest — they translate 1:1 replacing "vec3"->"float3", etc.

            float sdTorus(float3 p, float2 t)
            {
                return length(float2(length(p.xz)-t.x, p.y)) - t.y;
            }

            float sdCappedTorus(float3 p, float2 sc, float ra, float rb)
            {
                p.x = abs(p.x);
                float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
                return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
            }

            float sdCylinder(float3 p, float2 h)
            {
                float2 d = abs(float2(length(p.xz), p.y)) - h;
                return min(max(d.x,d.y),0.0) + length(max(d,0.0));
            }

            // Trivial opU (union with material id)
            float2 opU(float2 d1, float2 d2) { return (d1.x < d2.x) ? d1 : d2; }

            // Map function: returns float2(distance, materialID)
            float2 mapScene(float3 pos)
            {
                float2 res = float2( pos.y, 0.0 );

                // Example: place a sphere at (-2,0.25,0)
                if ( sdBox(pos - float3(-2.0,0.3,0.25), float3(0.3,0.3,1.0)) < res.x )
                {
                    res = opU(res, float2( sdSphere(pos - float3(-2.0,0.25, 0.0), 0.25), 26.9 ));
                }

                // central cluster (a few primitives)
                if ( sdBox(pos - float3(0.0,0.3,-1.0), float3(0.35,0.3,2.5)) < res.x )
                {
                    res = opU(res, float2( sdCappedTorus( (pos - float3(0.0,0.30,1.0)) * float3(1,-1,1), float2(0.866025,-0.5), 0.25, 0.05), 25.0) );
                    res = opU(res, float2( sdBox(pos - float3(0.0,0.25, 0.0), float3(0.3,0.25,0.2)), 16.9 ) );
                    res = opU(res, float2( sdCylinder(pos - float3(0.0,0.25,-2.0), float2(0.15,0.25)), 8.0 ) );
                }

                // more objects can be copied similarly...
                return res;
            }

            // raycast bounding + raymarch (simplified)
            float2 raycast(float3 ro, float3 rd)
            {
                float2 res = float2(-1.0,-1.0);
                float tmin = 1.0;
                float tmax = 20.0;

                // ground plane
                float tp1 = (0.0 - ro.y) / rd.y;
                if (tp1 > 0.0)
                {
                    tmax = min(tmax, tp1);
                    res = float2(tp1, 1.0);
                }

                // approximate bounding box for scene area (improves performance)
                // For correctness we do a local raymarch between tmin..tmax
                float t = tmin;
                for (int i=0; i<70 && t < tmax; ++i)
                {
                    float2 h = mapScene(ro + rd * t);
                    if (abs(h.x) < (0.0001 * t))
                    {
                        res = float2(t, h.y);
                        break;
                    }
                    t += max(h.x, 0.001); // ensure progress
                }

                return res;
            }

            // normal calc by sampling map
            float3 calcNormal(float3 pos)
            {
                float eps = 0.0005;
                float3 n = float3(0,0,0);
                // 4-sample trick:
                float3 e;
                e = 0.5773 * float3( 1,-1, 1 );
                n += e * mapScene(pos + eps * e).x;
                e = 0.5773 * float3( -1,-1, 1 );
                n += e * mapScene(pos + eps * e).x;
                e = 0.5773 * float3( 1, 1, -1 );
                n += e * mapScene(pos + eps * e).x;
                e = 0.5773 * float3( -1, 1, -1 );
                n += e * mapScene(pos + eps * e).x;
                return normalize(n);
            }

            // AO (ambient occlusion) simplified
            float calcAO(float3 pos, float3 nor)
            {
                float occ = 0.0;
                float sca = 1.0;
                for (int i=0; i<5; ++i)
                {
                    float h = 0.01 + 0.12 * (float(i) / 4.0);
                    float d = mapScene(pos + nor * h).x;
                    occ += (h - d) * sca;
                    sca *= 0.95;
                    if (occ > 0.35) break;
                }
                return saturate(1.0 - 3.0 * occ) * (0.5 + 0.5 * nor.y);
            }

            // soft shadow (fast version)
            float calcSoftShadow(float3 ro, float3 rd, float mint, float tmax)
            {
                float res = 1.0;
                float t = mint;
                for (int i=0; i<24; ++i)
                {
                    float h = mapScene(ro + rd * t).x;
                    float s = clamp(8.0 * h / t, 0.0, 1.0);
                    res = min(res, s);
                    t += clamp(h, 0.01, 0.2);
                    if (res < 0.004 || t > tmax) break;
                }
                res = saturate(res);
                return res * res * (3.0 - 2.0 * res);
            }

            // main shading routine (simplified but close to shadertoy)
            float3 render(float3 ro, float3 rd, float3 rdx, float3 rdy)
            {
                float3 col = float3(0.7, 0.7, 0.9) - max(rd.y, 0.0) * 0.3;

                float2 rr = raycast(ro, rd);
                float t = rr.x;
                float m = rr.y;
                if (m > -0.5)
                {
                    float3 pos = ro + t * rd;
                    float3 nor = (m < 1.5) ? float3(0.0,1.0,0.0) : calcNormal(pos);
                    float3 ref = reflect(rd, nor);

                    // base color by material id (m is used similarly to original)
                    float3 baseCol = 0.2 + 0.2 * sin(m * 2.0 + float3(0,1,2));
                    float ks = 1.0;

                    if (m < 1.5)
                    {
                        // plane checkerboard
                        float3 dpdx = ro.y * (rd / rd.y - rdx / rdx.y);
                        float3 dpdy = ro.y * (rd / rd.y - rdy / rdy.y);
                        float f = 0.5; // simplified: you can implement checkersGradBox if needed
                        baseCol = 0.15 + f * float3(0.05,0.05,0.05);
                        ks = 0.4;
                    }

                    float occ = calcAO(pos, nor);
                    float3 lin = float3(0,0,0);

                    // sun lighting
                    {
                        float3 lig = normalize(float3(-0.5, 0.4, -0.6));
                        float3 hal = normalize(lig - rd);
                        float dif = saturate(dot(nor, lig));
                        dif *= calcSoftShadow(pos, lig, 0.02, 2.5);
                        float spe = pow(saturate(dot(nor, hal)), 16.0);
                        spe *= dif;
                        spe *= 0.04 + 0.96 * pow(saturate(1.0 - dot(hal, lig)), 5.0);
                        lin += baseCol * 2.20 * dif * float3(1.30,1.00,0.70);
                        lin += 5.00 * spe * float3(1.30,1.00,0.70) * ks;
                    }

                    // sky
                    {
                        float dif = sqrt(saturate(0.5 + 0.5 * nor.y));
                        dif *= occ;
                        float spe = smoothstep(-0.2, 0.2, ref.y);
                        spe *= dif;
                        spe *= 0.04 + 0.96 * pow(saturate(1.0 + dot(nor, rd)), 5.0);
                        spe *= calcSoftShadow(pos, ref, 0.02, 2.5);
                        lin += baseCol * 0.60 * dif * float3(0.40,0.60,1.15);
                        lin += 2.00 * spe * float3(0.40,0.60,1.30) * ks;
                    }

                    // back light
                    {
                        float dif = saturate(dot(nor, normalize(float3(0.5,0.0,0.6)))) * saturate(1.0 - pos.y);
                        dif *= occ;
                        lin += baseCol * 0.55 * dif * float3(0.25,0.25,0.25);
                    }

                    // subsurface-ish
                    {
                        float dif = pow(saturate(1.0 + dot(nor, rd)), 2.0);
                        dif *= occ;
                        lin += baseCol * 0.25 * dif;
                    }

                    col = lin;
                    col = lerp(col, float3(0.7,0.7,0.9), 1.0 - exp(-0.0001 * t * t * t));
                }

                return saturate(col);
            }

            // camera setCamera: we will mimic the original camera calculation in shader for simplicity
            float3x3 setCamera(float3 ro, float3 ta, float cr)
            {
                float3 cw = normalize(ta - ro);
                float3 cp = float3(sin(cr), cos(cr), 0.0);
                float3 cu = normalize(cross(cw, cp));
                float3 cv = cross(cu, cw);
                // return as 3x3 where columns are cu, cv, cw
                return float3x3( cu.x, cv.x, cw.x,
                                 cu.y, cv.y, cw.y,
                                 cu.z, cv.z, cw.z );
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;
                float2 res = _Resolution.xy;
                float2 fragCoord = uv * res;

                // shadertoy uniforms equivalents
                float time = 32.0 + _TimeParams.y * 1.5; // matches original "time = 32 + iTime*1.5"
                float2 mouseN = _Mouse.xy / max(res, 1.0); // normalized mouse

                // camera
                float3 ta = float3(0.25, -0.75, -0.75);
                float3 ro = ta + float3( 4.5 * cos(0.1 * time + 7.0 * mouseN.x),
                                         2.2,
                                         4.5 * sin(0.1 * time + 7.0 * mouseN.x) );
                float3x3 ca = setCamera(ro, ta, 0.0);

                // pixel coords (like original)
                float2 p = (2.0 * fragCoord - res) / res.y;
                const float fl = 2.5;
                float3 rd = mul(ca, normalize(float3(p.x, p.y, fl)));

                // ray differentials (approx)
                float2 px = (2.0 * (fragCoord + float2(1.0, 0.0)) - res) / res.y;
                float2 py = (2.0 * (fragCoord + float2(0.0, 1.0)) - res) / res.y;
                float3 rdx = mul(ca, normalize(float3(px.x, px.y, fl)));
                float3 rdy = mul(ca, normalize(float3(py.x, py.y, fl)));

                float3 col = render(ro, rd, rdx, rdy);

                // gamma
                col = pow(col, float3(0.4545,0.4545,0.4545));

                return float4(col, 1.0);
            }

            ENDHLSL
        } // Pass
    } // SubShader
    FallBack "Diffuse"
}
