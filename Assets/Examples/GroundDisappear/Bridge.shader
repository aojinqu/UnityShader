// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Bridge"
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
			float dotResult5_g2 = dot( ase_worldNormal , ase_worldlightDir );
			float temp_output_13_0 = (dotResult5_g2*0.5 + 0.5);
			float4 temp_cast_0 = (temp_output_13_0).xxxx;
			float Subs37 = ( _Radius - _FadeRange );
			float Radius28 = _Radius;
			float3 temp_cast_1 = (StartPosArray[0]).xxx;
			float smoothstepResult14 = smoothstep( Subs37 , Radius28 , distance( temp_cast_1 , ase_worldPos ));
			float3 temp_cast_2 = (StartPosArray[1]).xxx;
			float smoothstepResult26 = smoothstep( Subs37 , Radius28 , distance( temp_cast_2 , ase_worldPos ));
			float temp_output_27_0 = ( smoothstepResult14 * smoothstepResult26 );
			clip( 0.99 - temp_output_27_0);
			#ifdef _DISAPPEAR_ON
				float4 staticSwitch51 = ( ( temp_output_13_0 * 0.4 ) + ( temp_output_27_0 * _outlineColor ) );
			#else
				float4 staticSwitch51 = temp_cast_0;
			#endif
			o.Emission = staticSwitch51.rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.CommentaryNode;42;-130.1438,-541.5317;Inherit;False;1011.952;317.5846;注册变量;6;10;34;41;28;37;33;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DistanceOpNode;23;-3.021287,462.5773;Inherit;False;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;558.1805,180.4663;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;13;83.28468,-172.3002;Inherit;False;Half Lambert Term;-1;;2;86299dc21373a954aa5772333626c9c1;0;1;3;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;764.4373,180.3667;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;17;878.6541,65.54491;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;14;359.4745,45.07748;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;387.0261,-97.5281;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.4;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;18;583.4982,479.2705;Inherit;False;Property;_outlineColor;outlineColor;3;0;Create;True;0;0;0;False;0;False;0.8490566,0.5099679,0.5099679,0;0,0.6512672,0.9294118,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;26;262.9353,466.2868;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;30;1.262909,671.9771;Inherit;False;28;Radius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;8;20.1218,-18.21495;Inherit;False;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;39;-9.649363,586.5034;Inherit;False;37;Subs;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;22.17484,102.3733;Inherit;False;37;Subs;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;31;23.53937,193.377;Inherit;False;28;Radius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-74.29115,-491.5318;Inherit;False;Property;_Radius;Radius;1;0;Create;True;0;0;0;False;0;False;0;5.18;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-80.14378,-338.9472;Inherit;False;Property;_FadeRange;FadeRange;2;0;Create;True;0;0;0;False;0;False;2;2.07;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;28;148.9622,-491.4236;Inherit;False;Radius;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;327.173,-367.7704;Inherit;False;Subs;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;33;175.64,-375.3547;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;43;-339.7534,-15.72771;Inherit;False;MyGlobalArray;0;1;0;False;False;0;1;False;Instance;41;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;41;629.1417,-402.8151;Inherit;False;StartPosArray;0;5;2;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GlobalArrayNode;44;-336.1463,445.3246;Inherit;False;MyGlobalArray;1;1;0;False;False;0;1;False;Instance;41;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;5;-518.9786,214.1777;Inherit;False;Property;_StartPos;StartPos;0;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PosVertexDataNode;7;-488.1317,65.2518;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;49;-351.3219,262.0697;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PosVertexDataNode;22;-569.4416,581.2487;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;50;-343.1962,597.2357;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;2;1470.8,-167.3247;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Bridge;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.ClipNode;11;999.3553,-93.54884;Inherit;False;3;0;COLOR;0,0,0,0;False;1;FLOAT;0.99;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;51;1216.094,-172.8283;Inherit;False;Property;_Disappear;Disappear;4;0;Create;True;0;0;0;False;0;False;1;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
WireConnection;23;0;44;0
WireConnection;23;1;50;0
WireConnection;27;0;14;0
WireConnection;27;1;26;0
WireConnection;19;0;27;0
WireConnection;19;1;18;0
WireConnection;17;0;20;0
WireConnection;17;1;19;0
WireConnection;14;0;8;0
WireConnection;14;1;40;0
WireConnection;14;2;31;0
WireConnection;20;0;13;0
WireConnection;26;0;23;0
WireConnection;26;1;39;0
WireConnection;26;2;30;0
WireConnection;8;0;43;0
WireConnection;8;1;49;0
WireConnection;28;0;10;0
WireConnection;37;0;33;0
WireConnection;33;0;10;0
WireConnection;33;1;34;0
WireConnection;2;2;51;0
WireConnection;11;0;17;0
WireConnection;11;2;27;0
WireConnection;51;1;13;0
WireConnection;51;0;11;0
ASEEND*/
//CHKSM=D27C7D87C0450FD8E65B6EC86CAF6040EB3EF367