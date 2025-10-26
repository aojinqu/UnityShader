// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "aj7/Bridge"
{
	Properties
	{
		_Radius("Radius", Float) = 0
		_FadeRange("FadeRange", Float) = 2
		_outlineColor("outlineColor", Color) = (0.8490566,0.5099679,0.5099679,0)
		[Toggle(_DISAPPEAR_ON)] _Disappear("Disappear", Float) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma multi_compile_local __ _DISAPPEAR_ON
		struct Input
		{
			float3 worldNormal;
			float3 worldPos;
		};
		//uniform 表示这个变量是 从外部传入的固定值，在一个 渲染批次（draw call）里保持不变。uniform = 外部提供的常量/参数，Shader 内不可修改
		int StartPosCount;
		uniform float4 StartPosArray[5];
		uniform float _Radius;
		uniform float _FadeRange;
		uniform float4 _outlineColor;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 ase_worldNormal = i.worldNormal;
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			//lambert 法线和光照模型
			fixed NdotL = dot( ase_worldNormal , ase_worldlightDir );
			fixed diffuse = (NdotL*0.5 + 0.5)*0.4;
			float outline =1; 
			float4 diffuseColor = diffuse;
            #ifdef _DISAPPEAR_ON
				float fadeMin = _Radius - _FadeRange;
				float fadeMax = _Radius;
				for(uint j=0;j<StartPosCount;j++)
				{
					float3 startPos = StartPosArray[j].xyz;
					float fade = saturate((distance( startPos , i.worldPos) - fadeMin)/(fadeMax-fadeMin));
					outline *= fade;
				}
				clip( 0.99 - outline);
				
				diffuseColor = diffuse  + ( outline * _outlineColor );
				o.Emission = diffuseColor.rgb;

			#else
				o.Emission = diffuse;
				
			#endif
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard  

		ENDCG
		Pass
		{
			Name "FORWARD"
			//Tags{ "LightMode" = "ShadowCaster" }
            Tags { "LightMode" = "ForwardBase" }

			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			//#pragma multi_compile_shadowcaster
			//#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };

			struct v2f
			{
				//V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
			};
			v2f vert( appdata v )
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT( v2f, o );

				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.worldPos = worldPos;
				//TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f i ) : SV_Target
			{
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				float3 worldPos = i.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = i.worldNormal;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				fixed4 c = 0;
				return 1;

			}
			ENDCG
		}
	}

}
