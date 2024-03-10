Shader "Custom/ToonGroundExam"
{
	Properties
	{
		_MainTex("主贴图", 2D) = "white" {}
		_YThreshold         ("岩浆平面高度", float) = 1
	}
		SubShader
		{
		Tags { "RenderType" = "Queue" "Queue" = "Geometry" }
		Pass
		{

			Tags
			{
				"LightMode" = "UniversalForward"
			}
			Zwrite On
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
 
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ Anti_Aliasing_ON
 
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
 
			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
 
			};
 
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
 
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _YThreshold;
 
			v2f vert(appdata v)
			{
				v2f o;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				if(o.worldPos.y < _YThreshold)
                {
                    o.worldPos.y = _YThreshold;
                }

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.pos = TransformWorldToHClip(o.worldPos);
 
				return o;
			}
 
			float4 _Color;
 
			float4 frag(v2f i) : SV_Target
			{
				float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.worldPos);
 
				Light mainLight = GetMainLight(SHADOW_COORDS);
				half shadow = MainLightRealtimeShadow(SHADOW_COORDS);
 
				return 1;
			}
			ENDHLSL
		}
	}
}