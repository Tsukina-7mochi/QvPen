﻿/*
 Original file :
 Storage for distribution - phi16
 https://github.com/phi16/VRC_storage
 rounded_trail.unitypackage
 LICENSE : CC0
*/

// 2024-01-01 added shadowcaster -- Silent
// 2020-04-16 seeing vertex color.
// 2019-09-26 customized for QvPen v2.
// 2019-09-09 customized for QvPen.

Shader "QvPen/rounded_trail_for_qv_pen"
{
	Properties
	{
		_Width ("Width", Float) = 0.005
		_NearClipDistance ("Near Clip Distance", Float) = 0.1
		_FarClipDistance ("Far Clip Distance", Float) = 100.0
	}
	SubShader
	{
		LOD 100
		Cull Off

		CGINCLUDE
		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			float4 color : COLOR;
		};

		struct v2g
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			float4 color : COLOR;
		};

		struct g2f
		{
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
			float4 color : COLOR;
			float d : TEXCOORD1;
		};

		float _Width;
		float _NearClipDistance;
		float _FarClipDistance;
		
		v2g vert (appdata v)
		{
			v2g o;
			o.vertex = v.vertex;
			o.uv = v.uv;
			o.color = v.color;
			return o;
		}

		[maxvertexcount(10)]
		void geom(triangle v2g IN[3], inout TriangleStream<g2f> stream) {
			const float dist = length(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, IN[0].vertex));
			if(dist < _NearClipDistance || dist > _FarClipDistance)
				return;

			if(IN[0].uv.x + IN[2].uv.x > IN[1].uv.x * 2)
				return;

			g2f o;
			o.uv = 0;
			o.color = IN[0].color;
			
			const float4 p = UnityObjectToClipPos(IN[0].vertex);
			const float4 q = UnityObjectToClipPos(IN[1].vertex);
			const float aspectRatio = -_ScreenParams.y / _ScreenParams.x;
			float2 d = p.xy / p.w - q.xy / q.w;
			d.x /= aspectRatio;
			const float l = length(d);
			o.d = l;
			d = l < 0.000001 ? float2(1, 0) : normalize(d);
			
			float2 w = _Width;
			w *= float2(aspectRatio, -1);
			w *= unity_CameraProjection._m11 / 1.732;
			float4 n = {d.yx, 0, 0};
			n.xy *= w;
			
			o.d = 0;
			o.vertex = p + n;
			stream.Append(o);
			o.vertex = p - n;
			stream.Append(o);
			o.vertex = q + n;
			stream.Append(o);
			o.vertex = q - n;
			stream.Append(o);
			stream.RestartStrip();
			
			o.d = 1;
			w *= 2;
			if(IN[1].uv.x >= 0.999999) {
				n.xy = (o.uv = float2(0, 1)) * w;
				o.vertex = q + n;
				stream.Append(o);
				n.xy = (o.uv = float2(-0.866, -0.5)) * w;
				o.vertex = q + n;
				stream.Append(o);
				n.xy = (o.uv = float2(0.866, -0.5)) * w;
				o.vertex = q + n;
				stream.Append(o);
				stream.RestartStrip();
			}
			
			n.xy = (o.uv = float2(0, 1)) * w;
			o.vertex = p + n;
			stream.Append(o);
			n.xy = (o.uv = float2(-0.866, -0.5)) * w;
			o.vertex = p + n;
			stream.Append(o);
			n.xy = (o.uv = float2(0.866, -0.5)) * w;
			o.vertex = p + n;
			stream.Append(o);
			stream.RestartStrip();
		}
		
		fixed4 frag (g2f i) : SV_Target
		{
			const float l = length(i.uv);
			clip(0.5 - min(i.d, l));
			#if UNITY_COLORSPACE_GAMMA
			return float4(i.color.rgb, 1);
			#else
			return float4(GammaToLinearSpace(i.color.rgb), 1);
			#endif
		}
		ENDCG
		
		// Add the ShadowCaster pass
		Pass 
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag_shadow
			#pragma multi_compile_shadowcaster

			#ifndef UNITY_PASS_SHADOWCASTER
				#define UNITY_PASS_SHADOWCASTER
			#endif

			float4 frag_shadow(g2f i) : SV_Target
			{
				float l = length(i.uv);
				clip(0.5 - min(i.d, l));
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			ENDCG
		}
	}
}
