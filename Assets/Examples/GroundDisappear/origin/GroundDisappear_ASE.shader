// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GroundDisappear_ASE"
{
	Properties
	{
		_Radius("Radius", Float) = 0
		_FadeRange("FadeRange", Float) = 2
		_OutlineColor("OutlineColor", Color) = (0,0.7479331,1,0)
		[Toggle(_DISAPPEARENABLED_ON)] _DisappearEnabled("DisappearEnabled", Float) = 0
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
		#pragma multi_compile_local __ _DISAPPEARENABLED_ON
		struct Input
		{
			float3 worldNormal;
			float3 worldPos;
		};

		uniform float4 StartPosArry[5];
		uniform float _Radius;
		uniform float _FadeRange;
		uniform float4 _OutlineColor;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 ase_worldNormal = i.worldNormal;
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult5_g1 = dot( ase_worldNormal , ase_worldlightDir );
			float temp_output_15_0 = ( (dotResult5_g1*0.5 + 0.5) * 0.4 );
			float4 temp_cast_0 = (temp_output_15_0).xxxx;
			float fadeRange27 = ( _Radius - _FadeRange );
			float radius24 = _Radius;
			float3 temp_cast_1 = (StartPosArry[0]).xxx;
			float smoothstepResult9 = smoothstep( fadeRange27 , radius24 , distance( temp_cast_1 , ase_worldPos ));
			float3 temp_cast_2 = (StartPosArry[1]).xxx;
			float smoothstepResult21 = smoothstep( fadeRange27 , radius24 , distance( temp_cast_2 , ase_worldPos ));
			float3 temp_cast_3 = (StartPosArry[2]).xxx;
			float smoothstepResult42 = smoothstep( fadeRange27 , radius24 , distance( temp_cast_3 , ase_worldPos ));
			float3 temp_cast_4 = (StartPosArry[3]).xxx;
			float smoothstepResult49 = smoothstep( fadeRange27 , radius24 , distance( temp_cast_4 , ase_worldPos ));
			float3 temp_cast_5 = (StartPosArry[4]).xxx;
			float smoothstepResult56 = smoothstep( fadeRange27 , radius24 , distance( temp_cast_5 , ase_worldPos ));
			float temp_output_22_0 = ( smoothstepResult9 * smoothstepResult21 * smoothstepResult42 * smoothstepResult49 * smoothstepResult56 );
			clip( 0.999 - temp_output_22_0);
			#ifdef _DISAPPEARENABLED_ON
				float4 staticSwitch69 = ( temp_output_15_0 + ( temp_output_22_0 * _OutlineColor ) );
			#else
				float4 staticSwitch69 = temp_cast_0;
			#endif
			o.Emission = staticSwitch69.rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit keepalpha fullforwardshadows 

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
				SurfaceOutput o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutput, o )
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
Node;AmplifyShaderEditor.CommentaryNode;32;-668.4573,-872.7696;Inherit;False;954.3794;291.5653;注册变量;6;6;10;11;24;27;65;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-618.4572,-696.2043;Inherit;False;Property;_FadeRange;FadeRange;1;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;6;-614.4926,-822.7697;Inherit;False;Property;_Radius;Radius;0;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;11;-435.7031,-717.277;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;43;-790.0085,935.4258;Inherit;False;Constant;_Int2;Int 2;5;0;Create;True;0;0;0;False;0;False;2;0;False;0;1;INT;0
Node;AmplifyShaderEditor.IntNode;36;-790.5807,488.4662;Inherit;False;Constant;_Inta;Inta;5;0;Create;True;0;0;0;False;0;False;1;0;False;0;1;INT;0
Node;AmplifyShaderEditor.IntNode;57;-819.5052,1846.131;Inherit;False;Constant;_Int4;Int 4;5;0;Create;True;0;0;0;False;0;False;4;0;False;0;1;INT;0
Node;AmplifyShaderEditor.IntNode;50;-823.1918,1403.682;Inherit;False;Constant;_Int3;Int 3;5;0;Create;True;0;0;0;False;0;False;3;0;False;0;1;INT;0
Node;AmplifyShaderEditor.IntNode;35;-809.65,-85.96938;Inherit;False;Constant;_Int0;Int 0;5;0;Create;True;0;0;0;False;0;False;0;0;False;0;1;INT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;24;-471.3558,-822.2994;Inherit;False;radius;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;-290.5573,-715.3924;Inherit;False;fadeRange;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;59;-641.0342,12.19064;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GlobalArrayNode;37;-645.1644,486.5736;Inherit;False;MyGlobalArray;0;1;0;False;False;0;1;False;Instance;65;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;44;-644.5922,933.5333;Inherit;False;MyGlobalArray;0;1;0;False;False;0;1;False;Instance;65;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;62;-679.1494,1517.067;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GlobalArrayNode;33;-643.4209,-84.97939;Inherit;False;MyGlobalArray;0;1;0;False;False;0;1;False;Instance;65;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;51;-677.7756,1401.79;Inherit;False;MyGlobalArray;0;1;0;False;False;0;1;False;Instance;65;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode;58;-674.089,1844.239;Inherit;False;MyGlobalArray;0;1;0;False;False;0;1;False;Instance;65;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;63;-674.6222,1948.263;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;61;-646.3284,1039.468;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;60;-652.6552,597.8953;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DistanceOpNode;39;-414.7042,999.1407;Inherit;False;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;30;-423.0037,742.7747;Inherit;False;24;radius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;5;-406.3182,-50.13494;Inherit;False;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;46;-447.8875,1467.397;Inherit;False;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;26;-427.7206,144.5698;Inherit;False;24;radius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;-455.6147,1657.99;Inherit;False;24;radius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;48;-458.7592,1587.243;Inherit;False;27;fadeRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;-422.4315,1189.734;Inherit;False;24;radius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;54;-451.9279,2100.439;Inherit;False;24;radius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;18;-415.2764,552.181;Inherit;False;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;29;-426.1482,672.028;Inherit;False;27;fadeRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;55;-455.0724,2029.692;Inherit;False;27;fadeRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;53;-444.2007,1909.846;Inherit;False;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-430.8651,73.82309;Inherit;False;27;fadeRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;41;-425.576,1118.987;Inherit;False;27;fadeRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;49;-235.0398,1530.586;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;9;-192.1308,20.03888;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;42;-201.8565,1062.33;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;21;-202.4288,615.3704;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;56;-231.3531,1973.035;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;8;259.9342,848.6237;Inherit;False;Half Lambert Term;-1;;1;86299dc21373a954aa5772333626c9c1;0;1;3;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;22;184.527,1067.016;Inherit;False;5;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;13;223.8638,1302.737;Inherit;False;Property;_OutlineColor;OutlineColor;2;0;Create;True;0;0;0;False;0;False;0,0.7479331,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;499.2756,1226.768;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;506.2495,857.6517;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.4;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;12;809.3848,1002.396;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClipNode;7;1037.145,1024.63;Inherit;False;3;0;COLOR;0,0,0,0;False;1;FLOAT;0.999;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;69;1298.238,858.4893;Inherit;False;Property;_DisappearEnabled;DisappearEnabled;3;0;Create;True;0;0;0;False;0;False;1;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GlobalArrayNode;65;10.30957,-755.2889;Inherit;False;StartPosArry;0;5;2;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;2;1690.805,949.5909;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;GroundDisappear_ASE;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;;0;False;;False;0;False;;0;False;;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;11;0;6;0
WireConnection;11;1;10;0
WireConnection;24;0;6;0
WireConnection;27;0;11;0
WireConnection;37;0;36;0
WireConnection;44;0;43;0
WireConnection;33;0;35;0
WireConnection;51;0;50;0
WireConnection;58;0;57;0
WireConnection;39;0;44;0
WireConnection;39;1;61;0
WireConnection;5;0;33;0
WireConnection;5;1;59;0
WireConnection;46;0;51;0
WireConnection;46;1;62;0
WireConnection;18;0;37;0
WireConnection;18;1;60;0
WireConnection;53;0;58;0
WireConnection;53;1;63;0
WireConnection;49;0;46;0
WireConnection;49;1;48;0
WireConnection;49;2;47;0
WireConnection;9;0;5;0
WireConnection;9;1;28;0
WireConnection;9;2;26;0
WireConnection;42;0;39;0
WireConnection;42;1;41;0
WireConnection;42;2;40;0
WireConnection;21;0;18;0
WireConnection;21;1;29;0
WireConnection;21;2;30;0
WireConnection;56;0;53;0
WireConnection;56;1;55;0
WireConnection;56;2;54;0
WireConnection;22;0;9;0
WireConnection;22;1;21;0
WireConnection;22;2;42;0
WireConnection;22;3;49;0
WireConnection;22;4;56;0
WireConnection;14;0;22;0
WireConnection;14;1;13;0
WireConnection;15;0;8;0
WireConnection;12;0;15;0
WireConnection;12;1;14;0
WireConnection;7;0;12;0
WireConnection;7;2;22;0
WireConnection;69;1;15;0
WireConnection;69;0;7;0
WireConnection;2;2;69;0
ASEEND*/
//CHKSM=5F08679C4860B848DD00C7737FF8E37FF59DCB7D