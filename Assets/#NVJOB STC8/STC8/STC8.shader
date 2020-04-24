// Copyright (c) 2016 Unity Technologies. MIT license - license_unity.txt
// #NVJOB STC8. MIT license - license_nvjob.txt
// #NVJOB STC8 V3.2 - https://nvjob.github.io/unity/nvjob-stc-8
// #NVJOB Nicholas Veselov - https://nvjob.github.io


Shader "#NVJOB/STC8" {


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Properties {
//----------------------------------------------

[HideInInspector]_BillboardShadowFade("Billboard Shadow Fade", Range(0.0, 1.0)) = 0.5
[HideInInspector][Enum(Back,2,Off,0)] _Cull("Backface Culling", Int) = 2
[HideInInspector]_Cutoff("Alpha Cutoff", Range(0.01,0.99)) = 0.333

[HideInInspector]_MainTex ("Main Texture (Transparency)", 2D) = "white" {}
[HideInInspector][HDR]_Color ("Main Color", Color) = (1,1,1,1)
[HideInInspector][HDR]_HueVariationColor ("Hue Color", Color) = (1.0,0.5,0.0,0.1)

[HideInInspector][NoScaleOffset]_ExtraTex("Smoothness (R), Metallic (G), AO (B)", 2D) = "(0.5, 0.0, 1.0)" {}
[HideInInspector]_SmoothnessStrength("Smoothness Strength", Range(0.0, 10.0)) = 1
[HideInInspector]_SmoothnessInts("Smoothness Intensity", Range(0.0, 10.0)) = 1
[HideInInspector]_MetallicStrength("Metallic Strength", Range(0.0, 10.0)) = 1
[HideInInspector]_OcclusionStrength("Occlusion Strength", Range(0.0, 10.0)) = 1
[HideInInspector]_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
[HideInInspector]_Metallic("Metallic", Range(0.0, 1.0)) = 0.0

[HideInInspector][NoScaleOffset]_SubsurfaceTex("Subsurface (RGB)", 2D) = "white" {}
[HideInInspector][HDR]_SubsurfaceColor("Subsurface Color", Color) = (1,1,1,1)
[HideInInspector]_SubsurfaceIndirect("Subsurface Indirect", Range(0.0, 1.0)) = 0.25
[HideInInspector]_SubsurfaceRough("Subsurface Rough", Range(0.0, 10.0)) = 1

[HideInInspector][NoScaleOffset]_BumpMap ("Normal Map Texture", 2D) = "bump" {}
[HideInInspector]_IntensityNm("Strength Normal", Range(-10, 10)) = 1

[HideInInspector]_Brightness("Brightness", Range(0, 5)) = 1
[HideInInspector]_Saturation("Saturation", Range(0, 10)) = 1
[HideInInspector]_Contrast("Contrast", Range(-1, 5)) = 1

[HideInInspector][KeywordEnum(None,Fastest,Fast,Better,Best,Palm)] _WindQuality("Wind Quality", Range(0,5)) = 0
[HideInInspector]_WindSpeed("Wind Speed", Range(0.01, 10)) = 1
[HideInInspector]_WindAmplitude("Wind Amplitude", Range(0.01, 10)) = 1
[HideInInspector]_WindDegreeSlope("Wind Degree Slope", Range(0.01, 10)) = 1
[HideInInspector]_LeafRipple("Leaf Ripple", Range(0.01, 100)) = 1
[HideInInspector]_LeafRippleSpeed("Leaf Ripple Speed", Range(0.01, 10)) = 1
[HideInInspector]_LeafTumble("Leaf Tumble", Range(0.01, 10)) = 1
[HideInInspector]_LeafTumbleSpeed("Leaf Tumble Speed", Range(0.01, 5)) = 1
[HideInInspector]_BranchRipple("Branch Ripple", Range(0.01, 20)) = 1
[HideInInspector]_BranchRippleSpeed("Branch Ripple Speed", Range(0.01, 10)) = 1

[HideInInspector]_BranchWhip("Elasticity", Range(0.01, 10)) = 1
[HideInInspector]_BranchTurbulences("Turbulences", Range(0.01, 10)) = 1
[HideInInspector]_BranchForceHeaviness("Branch Force Wind", Range(0.01, 10)) = 1
[HideInInspector]_BranchHeaviness("Branch Heaviness", Range(-10, 10)) = 1

//----------------------------------------------
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


SubShader{
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" "DisableBatching"="LODFading" }
LOD 400
Cull [_Cull]

CGPROGRAM
#pragma surface STCShaderSurf STCShaderSubsurface vertex:STCShaderVert dithercrossfade addshadow exclude_path:prepass
#pragma target 3.0
#pragma multi_compile_vertex LOD_FADE_PERCENTAGE
#pragma instancing_options assumeuniformscaling maxcount:50
#pragma shader_feature_local _WINDQUALITY_NONE _WINDQUALITY_FASTEST _WINDQUALITY_FAST _WINDQUALITY_BETTER _WINDQUALITY_BEST _WINDQUALITY_PALM
#pragma shader_feature_local EFFECT_BILLBOARD
#pragma shader_feature_local EFFECT_HUE_VARIATION
#pragma shader_feature_local EFFECT_SUBSURFACE
#pragma shader_feature_local EFFECT_BUMP
#pragma shader_feature_local EFFECT_EXTRATEX
#pragma shader_feature COLOR_TUNING
#define EFFECT_BACKSIDE_NORMALS
#define ENABLE_WIND

//----------------------------------------------

#include "STC8.cginc"

//----------------------------------------------

ENDCG

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// targeting SM2.0: Many effects are disabled for fewer instructions


SubShader {
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout" "DisableBatching"="LODFading" }
LOD 400
Cull [_Cull]

CGPROGRAM
#pragma surface STCShaderSurf Standard vertex:STCShaderVert addshadow noinstancing
#pragma multi_compile_vertex LOD_FADE_PERCENTAGE
#pragma shader_feature_local EFFECT_BILLBOARD
#pragma shader_feature_local EFFECT_EXTRATEX

//----------------------------------------------

#include "STC8.cginc"

//----------------------------------------------

ENDCG

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
}


FallBack "Transparent/Cutout/VertexLit"
CustomEditor "STC8Material"

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}