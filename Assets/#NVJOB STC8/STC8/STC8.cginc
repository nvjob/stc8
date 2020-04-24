// Copyright (c) 2016 Unity Technologies. MIT license - license_unity.txt
// #NVJOB STC8. MIT license - license_nvjob.txt
// #NVJOB STC8 V3.2 - https://nvjob.github.io/unity/nvjob-stc-8
// #NVJOB Nicholas Veselov - https://nvjob.github.io


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#if defined(ENABLE_WIND) && !defined(_WINDQUALITY_NONE)

#define STCShader_Y_UP
#define wind_cross(a, b) cross((a), (b))

CBUFFER_START(STCShaderWind)
float4 _ST_WindVector, _ST_WindGlobal, _ST_WindBranch, _ST_WindBranchTwitch, _ST_WindBranchWhip, _ST_WindBranchAnchor, _ST_WindBranchAdherences, _ST_WindTurbulences, _ST_WindLeaf1Ripple, _ST_WindLeaf1Tumble, _ST_WindLeaf1Twitch, _ST_WindLeaf2Ripple, _ST_WindLeaf2Tumble, _ST_WindLeaf2Twitch, _ST_WindFrondRipple, _ST_WindAnimation;
CBUFFER_END

uniform half _WindSpeed, _WindAmplitude, _WindDegreeSlope, _LeafRipple, _LeafRippleSpeed, _BranchRipple, _BranchRippleSpeed, _LeafTumble, _LeafTumbleSpeed, _BranchWhip, _BranchTurbulences, _BranchForceHeaviness, _BranchHeaviness;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Unpack Normal From Float

float3 UnpackNormalFromFloat(float fValue) {
float3 vDecodeKey = float3(16.0, 1.0, 0.0625);
float3 vDecodedValue = frac(fValue / vDecodeKey);
return (vDecodedValue * 2.0 - 1.0);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Trig Approximate

float4 TrigApproximate(float4 vData) {
float4 TrianglevData = abs((frac(vData + 0.5) * 2.0) - 1.0);
return ((TrianglevData * TrianglevData * (3.0 - 2.0 * TrianglevData)) - 0.5) * 2.0;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Twitch

float Twitch(float3 vPos, float fAmount, float fSharpness, float fTime) {
const float c_fTwitchFudge = 0.87;
float4 vOscillations = TrigApproximate(float4(fTime + (vPos.x + vPos.z), c_fTwitchFudge * fTime + vPos.y, 0.0, 0.0));
float fTwitch = vOscillations.x * vOscillations.y * vOscillations.y;
fTwitch = (fTwitch + 1.0) * 0.5;
return fAmount * pow(saturate(fTwitch), fSharpness);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Oscillate

float Oscillate(float3 vPos, float fTime, float fOffset, float fWeight, float fWhip, bool bWhip, bool bRoll, bool bComplex, float fTwitch, float fTwitchFreqScale, inout float4 vOscillations, float3 vRotatedWindVector) {
float fOscillation = 1.0;
if (bComplex) {
if (bWhip) vOscillations = TrigApproximate(float4(fTime + fOffset, fTime * fTwitchFreqScale + fOffset, fTwitchFreqScale * 0.5 * (fTime + fOffset), fTime + fOffset + (1.0 - fWeight)));
else vOscillations = TrigApproximate(float4(fTime + fOffset, fTime * fTwitchFreqScale + fOffset, fTwitchFreqScale * 0.5 * (fTime + fOffset), 0.0));
float fFineDetail = vOscillations.x;
float fBroadDetail = vOscillations.y * vOscillations.z;
float fTarget = 1.0;
float fAmount = fBroadDetail;
if (fBroadDetail < 0.0) {
fTarget = -fTarget;
fAmount = -fAmount;
}
fBroadDetail = lerp(fBroadDetail, fTarget, fAmount);
fBroadDetail = lerp(fBroadDetail, fTarget, fAmount);
fOscillation = fBroadDetail * fTwitch * (1.0 - _ST_WindVector.w) + fFineDetail * (1.0 - fTwitch);
if (bWhip) fOscillation *= 1.0 + (vOscillations.w * fWhip);
}
else {
if (bWhip) vOscillations = TrigApproximate(float4(fTime + fOffset, fTime * 0.689 + fOffset, 0.0, fTime + fOffset + (1.0 - fWeight)));
else vOscillations = TrigApproximate(float4(fTime + fOffset, fTime * 0.689 + fOffset, 0.0, 0.0));
fOscillation = vOscillations.x + vOscillations.y * vOscillations.x;
if (bWhip) fOscillation *= 1.0 + (vOscillations.w * fWhip);
}
return fOscillation;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Turbulence

float Turbulence(float fTime, float fOffset, float fGlobalTime, float fTurbulence) {
const float c_fTurbulenceFactor = 0.1;
float4 vOscillations = TrigApproximate(float4(fTime * c_fTurbulenceFactor + fOffset, fGlobalTime * fTurbulence * c_fTurbulenceFactor + fOffset, 0.0, 0.0));
return 1.0 - (vOscillations.x * vOscillations.y * vOscillations.x * vOscillations.y * fTurbulence);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Global Wind

float3 GlobalWind(float3 vPos, float3 vInstancePos, bool bPreserveShape, float3 vRotatedWindVector, float time) {
float fLength = 1.0;
if (bPreserveShape) fLength = length(vPos.xyz);
#ifdef STCShader_Z_UP
float fAdjust = max(vPos.z - (1.0 / _ST_WindGlobal.z) * 0.25, 0.0) * _ST_WindGlobal.z;
#else
float fAdjust = max(vPos.y - (1.0 / _ST_WindGlobal.z) * 0.25, 0.0) * _ST_WindGlobal.z;
#endif
if (fAdjust != 0.0) fAdjust = pow(fAdjust, _ST_WindGlobal.w);
float4 vOscillations = TrigApproximate(float4(vInstancePos.x + time, vInstancePos.y + time * 0.8, 0.0, 0.0));
float fOsc = vOscillations.x + (vOscillations.y * vOscillations.y);
float fMoveAmount = _ST_WindGlobal.y * fOsc;
fMoveAmount += _ST_WindBranchAdherences.x / _ST_WindGlobal.z;
fMoveAmount *= fAdjust;
#ifdef STCShader_Z_UP
vPos.xy += vRotatedWindVector.xy * fMoveAmount;
#else
vPos.xz += vRotatedWindVector.xz * fMoveAmount;
#endif
if (bPreserveShape) vPos.xyz = normalize(vPos.xyz) * fLength;
return vPos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Simple Branch Wind

float3 SimpleBranchWind(float3 vPos, float3 vInstancePos, float fWeight, float fOffset, float fTime, float fDistance, float fTwitch, float fTwitchScale, float fWhip, bool bWhip, bool bRoll, bool bComplex, float3 vRotatedWindVector) {
float3 vWindVector = UnpackNormalFromFloat(fOffset);
vWindVector = vWindVector * fWeight;
fTime += vInstancePos.x + vInstancePos.y;
float4 vOscillations;
float fOsc = Oscillate(vPos, fTime, fOffset, fWeight, fWhip, bWhip, bRoll, bComplex, fTwitch, fTwitchScale, vOscillations, vRotatedWindVector);
vPos.xyz += vWindVector * fOsc * fDistance;
return vPos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Directional Branch Wind Frond Style

float3 DirectionalBranchWindFrondStyle(float3 vPos, float3 vInstancePos, float fWeight, float fOffset, float fTime, float fDistance, float fTurbulence, float fAdherence, float fTwitch, float fTwitchScale, float fWhip, bool bWhip, bool bRoll, bool bComplex, bool bTurbulence, float3 vRotatedWindVector, float3 vRotatedBranchAnchor) {
float3 vWindVector = UnpackNormalFromFloat(fOffset);
vWindVector = vWindVector * fWeight;
fTime += vInstancePos.x + vInstancePos.y;
float4 vOscillations;
float fOsc = Oscillate(vPos, fTime, fOffset, fWeight, fWhip, bWhip, false, bComplex, fTwitch, fTwitchScale, vOscillations, vRotatedWindVector);
vPos.xyz += vWindVector * fOsc * fDistance;
float fAdherenceScale = 1.0;
if (bTurbulence)
fAdherenceScale = Turbulence(fTime, fOffset, _ST_WindAnimation.x, fTurbulence);
if (bWhip) fAdherenceScale += vOscillations.w * _ST_WindVector.w * fWhip;
float3 vWindAdherenceVector = vRotatedBranchAnchor - vPos.xyz;
vPos.xyz += vWindAdherenceVector * fAdherence * fAdherenceScale * fWeight;
return vPos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Branch Wind 

// Apply only to better, best, palm winds
float3 BranchWind(bool isPalmWind, float3 vPos, float3 vInstancePos, float4 vWindData, float3 vRotatedWindVector, float3 vRotatedBranchAnchor) {
if (isPalmWind) vPos = DirectionalBranchWindFrondStyle(vPos, vInstancePos, vWindData.x, vWindData.y, _ST_WindBranch.x, _ST_WindBranch.y, _ST_WindTurbulences.x, _ST_WindBranchAdherences.y, _ST_WindBranchTwitch.x, _ST_WindBranchTwitch.y, _ST_WindBranchWhip.x, true, false, true, true, vRotatedWindVector, vRotatedBranchAnchor);
else vPos = SimpleBranchWind(vPos, vInstancePos, vWindData.x, vWindData.y, _ST_WindBranch.x, _ST_WindBranch.y, _ST_WindBranchTwitch.x, _ST_WindBranchTwitch.y, _ST_WindBranchWhip.x, false, false, true, vRotatedWindVector);
return vPos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Leaf Ripple

float3 LeafRipple(float3 vPos, inout float3 vDirection, float fScale, float fPackedRippleDir, float fTime, float fAmount, bool bDirectional, float fTrigOffset) {
float4 vInput = float4(fTime + fTrigOffset, 0.0, 0.0, 0.0);
float fMoveAmount = fAmount * TrigApproximate(vInput).x;
if (bDirectional) vPos.xyz += vDirection.xyz * fMoveAmount * fScale;
else {
float3 vRippleDir = UnpackNormalFromFloat(fPackedRippleDir);
vPos.xyz += vRippleDir * fMoveAmount * fScale;
}
return vPos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Leaf Tumble

float3x3 RotationMatrix(float3 vAxis, float fAngle) {
float2 vSinCos;
#ifdef OPENGL
vSinCos.x = sin(fAngle);
vSinCos.y = cos(fAngle);
#else
sincos(fAngle, vSinCos.x, vSinCos.y);
#endif
const float c = vSinCos.y;
const float s = vSinCos.x;
const float t = 1.0 - c;
const float x = vAxis.x;
const float y = vAxis.y;
const float z = vAxis.z;
return float3x3(t * x * x + c, t * x * y - s * z, t * x * z + s * y, t * x * y + s * z, t * y * y + c, t * y * z - s * x, t * x * z - s * y, t * y * z + s * x, t * z * z + c);
}

//----------------------------------------------

float3 LeafTumble(float3 vPos, inout float3 vDirection, float fScale, float3 vAnchor, float3 vGrowthDir, float fTrigOffset, float fTime, float fFlip, float fTwist, float fAdherence, float3 vTwitch, float4 vRoll, bool bTwitch, bool bRoll, float3 vRotatedWindVector) {
float3 vFracs = frac((vAnchor + fTrigOffset) * 30.3);
float fOffset = vFracs.x + vFracs.y + vFracs.z;
float4 vOscillations = TrigApproximate(float4(fTime + fOffset, fTime * 0.75 - fOffset, fTime * 0.01 + fOffset, fTime * 1.0 + fOffset));
float3 vOriginPos = vPos.xyz - vAnchor;
float fLength = length(vOriginPos);
float fOsc = vOscillations.x + vOscillations.y * vOscillations.y;
float3x3 matTumble = RotationMatrix(vGrowthDir, fScale * fTwist * fOsc);
float3 vAxis = wind_cross(vGrowthDir, vRotatedWindVector);
float fDot = clamp(dot(vRotatedWindVector, vGrowthDir), -1.0, 1.0);
#ifdef STCShader_Z_UP
vAxis.z += fDot;
#else
vAxis.y += fDot;
#endif
vAxis = normalize(vAxis);
float fAngle = acos(fDot);
float fAdherenceScale = 1.0;
fOsc = vOscillations.y - vOscillations.x * vOscillations.x;
float fTwitch = 0.0;
if (bTwitch)
fTwitch = Twitch(vAnchor.xyz, vTwitch.x, vTwitch.y, vTwitch.z + fOffset);
matTumble = mul(matTumble, RotationMatrix(vAxis, fScale * (fAngle * fAdherence * fAdherenceScale + fOsc * fFlip + fTwitch)));
vDirection = mul(matTumble, vDirection);
vOriginPos = mul(matTumble, vOriginPos);
vOriginPos = normalize(vOriginPos) * fLength;
return (vOriginPos + vAnchor);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Leaf Wind
//  Optimized (for instruction count) version. Assumes leaf 1 and 2 have the same options

float3 LeafWind(bool isBestWind, bool bLeaf2, float3 vPos, inout float3 vDirection, float fScale, float3 vAnchor, float fPackedGrowthDir, float fPackedRippleDir, float fRippleTrigOffset, float3 vRotatedWindVector) {
vPos = LeafRipple(vPos, vDirection, fScale, fPackedRippleDir, (bLeaf2 ? _ST_WindLeaf2Ripple.x : _ST_WindLeaf1Ripple.x), (bLeaf2 ? _ST_WindLeaf2Ripple.y : _ST_WindLeaf1Ripple.y), false, fRippleTrigOffset);
if (isBestWind) {
float3 vGrowthDir = UnpackNormalFromFloat(fPackedGrowthDir);
vPos = LeafTumble(vPos, vDirection, fScale, vAnchor, vGrowthDir, fPackedGrowthDir,
(bLeaf2 ? _ST_WindLeaf2Tumble.x : _ST_WindLeaf1Tumble.x),
(bLeaf2 ? _ST_WindLeaf2Tumble.y : _ST_WindLeaf1Tumble.y),
(bLeaf2 ? _ST_WindLeaf2Tumble.z : _ST_WindLeaf1Tumble.z),
(bLeaf2 ? _ST_WindLeaf2Tumble.w : _ST_WindLeaf1Tumble.w),
(bLeaf2 ? _ST_WindLeaf2Twitch.xyz : _ST_WindLeaf1Twitch.xyz),
0.0f,
(bLeaf2 ? true : true),
(bLeaf2 ? true : true),
vRotatedWindVector);
}
return vPos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Ripple Frond One Sided

float3 RippleFrondOneSided(float3 vPos, inout float3 vDirection, float fU, float fV, float fRippleScale
#ifdef WIND_EFFECT_FROND_RIPPLE_ADJUST_LIGHTING
, float3 vBinormal, float3 vTangent
#endif
) {
float fOffset = 0.0;
if (fU < 0.5)
fOffset = 0.75;
float4 vOscillations = TrigApproximate(float4((_ST_WindFrondRipple.x + fV) * _ST_WindFrondRipple.z + fOffset, 0.0, 0.0, 0.0));
float fAmount = fRippleScale * vOscillations.x * _ST_WindFrondRipple.y;
float3 vOffset = fAmount * vDirection;
vPos.xyz += vOffset;
#ifdef WIND_EFFECT_FROND_RIPPLE_ADJUST_LIGHTING
vTangent.xyz = normalize(vTangent.xyz + vOffset * _ST_WindFrondRipple.w);
float3 vNewNormal = normalize(wind_cross(vBinormal.xyz, vTangent.xyz));
if (dot(vNewNormal, vDirection.xyz) < 0.0)
vNewNormal = -vNewNormal;
vDirection.xyz = vNewNormal;
#endif
return vPos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Ripple Frond Two Sided

float3 RippleFrondTwoSided(float3 vPos, inout float3 vDirection, float fU, float fLengthPercent, float fPackedRippleDir, float fRippleScale
#ifdef WIND_EFFECT_FROND_RIPPLE_ADJUST_LIGHTING
, float3 vBinormal, float3 vTangent
#endif
) {
float4 vOscillations = TrigApproximate(float4(_ST_WindFrondRipple.x * fLengthPercent * _ST_WindFrondRipple.z, 0.0, 0.0, 0.0));
float3 vRippleDir = UnpackNormalFromFloat(fPackedRippleDir);
float fAmount = fRippleScale * vOscillations.x * _ST_WindFrondRipple.y;
float3 vOffset = fAmount * vRippleDir;
vPos.xyz += vOffset;
#ifdef WIND_EFFECT_FROND_RIPPLE_ADJUST_LIGHTING
vTangent.xyz = normalize(vTangent.xyz + vOffset * _ST_WindFrondRipple.w);
float3 vNewNormal = normalize(wind_cross(vBinormal.xyz, vTangent.xyz));
if (dot(vNewNormal, vDirection.xyz) < 0.0)
vNewNormal = -vNewNormal;
vDirection.xyz = vNewNormal;
#endif
return vPos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Ripple Frond

float3 RippleFrond(float3 vPos, inout float3 vDirection, float fU, float fV, float fPackedRippleDir, float fRippleScale, float fLenghtPercent
#ifdef WIND_EFFECT_FROND_RIPPLE_ADJUST_LIGHTING
, float3 vBinormal, float3 vTangent
#endif
) {
return RippleFrondOneSided(vPos, vDirection, fU, fV, fRippleScale
#ifdef WIND_EFFECT_FROND_RIPPLE_ADJUST_LIGHTING
, vBinormal, vTangent
#endif
);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Custom Wind

void CustomWind() {
_ST_WindGlobal.x *= _WindSpeed;
_ST_WindGlobal.y *= _WindAmplitude;
_ST_WindGlobal.z *= _WindDegreeSlope;
_ST_WindLeaf1Ripple.y *= _LeafRipple;
_ST_WindLeaf2Ripple.y *= _LeafRipple;
_ST_WindLeaf1Ripple.x *= _LeafRippleSpeed;
_ST_WindLeaf2Ripple.x *= _LeafRippleSpeed;
_ST_WindLeaf1Tumble.yz *= _LeafTumble;
_ST_WindLeaf2Tumble.yz *= _LeafTumble;
_ST_WindLeaf1Tumble.x *= _LeafTumbleSpeed;
_ST_WindLeaf2Tumble.x *= _LeafTumbleSpeed;
_ST_WindBranch.y *= _BranchRipple;
_ST_WindBranch.x *= _BranchRippleSpeed;
_ST_WindBranchWhip.x *= _BranchWhip;
_ST_WindTurbulences.x *= _BranchTurbulences;
_ST_WindBranchAnchor.xyz *= float3(1, _BranchHeaviness, 1);
_ST_WindBranchAnchor.w *= _BranchForceHeaviness;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////


float _WindEnabled;
UNITY_INSTANCING_BUFFER_START(STWind)
UNITY_DEFINE_INSTANCED_PROP(float, _GlobalWindTime)
UNITY_INSTANCING_BUFFER_END(STWind)


#endif


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


struct Input{
half2 uv_MainTex : TEXCOORD0;
fixed4 color : COLOR;
#ifdef EFFECT_BACKSIDE_NORMALS
fixed facing : VFACE;
#endif
};


///////////////////////////////////////////////////////////////////////////////////////////////////////////////


sampler2D _MainTex;
fixed4 _Color;
int _Cull;
fixed _Cutoff;

#ifdef EFFECT_BUMP
sampler2D _BumpMap;
half _IntensityNm;
#endif

#ifdef EFFECT_EXTRATEX
sampler2D _ExtraTex;
half _SmoothnessInts, _SmoothnessStrength, _MetallicStrength, _OcclusionStrength;
#else
half _Glossiness, _Metallic;
#endif

#ifdef EFFECT_HUE_VARIATION
half4 _HueVariationColor;
#endif

#ifdef EFFECT_BILLBOARD
half _BillboardShadowFade;
#endif

#ifdef EFFECT_SUBSURFACE
sampler2D _SubsurfaceTex;
fixed4 _SubsurfaceColor;
half _SubsurfaceIndirect, _SubsurfaceRough;
#endif

#ifdef COLOR_TUNING
half _Saturation, _Contrast, _Brightness;
#endif

#define STC_GTYPE_BRANCH 0
#define STC_GTYPE_FROND 1
#define STC_GTYPE_LEAF 2
#define STC_GTYPE_FACINGLEAF 3


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  OffsetSTCShaderVertex

void OffsetSTCShaderVertex(inout appdata_full data, float lodValue){
// smooth LOD
#if defined(LOD_FADE_PERCENTAGE) && !defined(EFFECT_BILLBOARD)
data.vertex.xyz = lerp(data.vertex.xyz, data.texcoord2.xyz, lodValue);
#endif

// wind
#if defined(ENABLE_WIND) && !defined(_WINDQUALITY_NONE)
if (_WindEnabled > 0){
CustomWind();

float3 rotatedWindVector = mul(_ST_WindVector.xyz, (float3x3)unity_ObjectToWorld);
float windLength = length(rotatedWindVector);
if (windLength < 1e-5) return;
rotatedWindVector /= windLength;

float3 treePos = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);
float3 windyPosition = data.vertex.xyz;

#ifndef EFFECT_BILLBOARD
// geometry type
float geometryType = (int)(data.texcoord3.w + 0.25);
bool leafTwo = false;
if (geometryType > STC_GTYPE_FACINGLEAF){
geometryType -= 2;
leafTwo = true;
}

// leaves
if (geometryType > STC_GTYPE_FROND){
// remove anchor position
float3 anchor = float3(data.texcoord1.zw, data.texcoord2.w);
windyPosition -= anchor;

if (geometryType == STC_GTYPE_FACINGLEAF){
// face camera-facing leaf to camera
float offsetLen = length(windyPosition);
windyPosition = mul(windyPosition.xyz, (float3x3)UNITY_MATRIX_IT_MV); // inv(MV) * windyPosition
windyPosition = normalize(windyPosition) * offsetLen; // make sure the offset vector is still scaled
}

// leaf wind
#if defined(_WINDQUALITY_FAST) || defined(_WINDQUALITY_BETTER) || defined(_WINDQUALITY_BEST)
#ifdef _WINDQUALITY_BEST
bool bBestWind = true;
#else
bool bBestWind = false;
#endif
float leafWindTrigOffset = anchor.x + anchor.y;
windyPosition = LeafWind(bBestWind, leafTwo, windyPosition, data.normal, data.texcoord3.x, float3(0,0,0), data.texcoord3.y, data.texcoord3.z, leafWindTrigOffset, rotatedWindVector);
#endif

// move back out to anchor
windyPosition += anchor;
}

// frond wind
bool bPalmWind = false;
#ifdef _WINDQUALITY_PALM
bPalmWind = true;
if (geometryType == STC_GTYPE_FROND){
windyPosition = RippleFrond(windyPosition, data.normal, data.texcoord.x, data.texcoord.y, data.texcoord3.x, data.texcoord3.y, data.texcoord3.z);
}
#endif

// branch wind (applies to all 3D geometry)
#if defined(_WINDQUALITY_BETTER) || defined(_WINDQUALITY_BEST) || defined(_WINDQUALITY_PALM)
float3 rotatedBranchAnchor = normalize(mul(_ST_WindBranchAnchor.xyz, (float3x3)unity_ObjectToWorld)) * _ST_WindBranchAnchor.w;
windyPosition = BranchWind(bPalmWind, windyPosition, treePos, float4(data.texcoord.zw, 0, 0), rotatedWindVector, rotatedBranchAnchor);
#endif

#endif // !EFFECT_BILLBOARD

// global wind
float globalWindTime = _ST_WindGlobal.x;
#if defined(EFFECT_BILLBOARD) && defined(UNITY_INSTANCING_ENABLED)
globalWindTime += UNITY_ACCESS_INSTANCED_PROP(STWind, _GlobalWindTime);
#endif
windyPosition = GlobalWind(windyPosition, treePos, true, rotatedWindVector, globalWindTime);
data.vertex.xyz = windyPosition;
}
#endif
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  vertex program


void STCShaderVert(inout appdata_full v) {
OffsetSTCShaderVertex(v, unity_LODFade.x);
float3 treePos = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);
#if defined(EFFECT_BILLBOARD)
bool topDown = (v.texcoord.z > 0.5);
float3 viewDir = UNITY_MATRIX_IT_MV[2].xyz;
float3 cameraDir = normalize(mul((float3x3)unity_WorldToObject, _WorldSpaceCameraPos - treePos));
float viewDot = max(dot(viewDir, v.normal), dot(cameraDir, v.normal));
viewDot *= viewDot;
viewDot *= viewDot;
viewDot += topDown ? 0.38 : 0.18;
v.color = float4(1, 1, 1, clamp(viewDot, 0, 1));
if (viewDot < 0.3333) v.vertex.xyz = float3(0,0,0);
if (topDown) v.normal += cameraDir;
else {
half3 binormal = cross(v.normal, v.tangent.xyz) * v.tangent.w;
float3 right = cross(cameraDir, binormal);
v.normal = cross(binormal, right);
}
v.normal = normalize(v.normal);
#endif
#ifdef EFFECT_HUE_VARIATION
float hueVariationAmount = frac(treePos.x + treePos.y + treePos.z);
v.color.g = saturate(hueVariationAmount * _HueVariationColor.a);
#endif
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  lighting function to add subsurface


half4 LightingSTCShaderSubsurface(inout SurfaceOutputStandard s, half3 viewDir, UnityGI gi){
#ifdef EFFECT_SUBSURFACE
half fSubsurfaceRough = 0.7 - s.Smoothness * 0.5;
fSubsurfaceRough *= _SubsurfaceRough;
half fSubsurface = GGXTerm(clamp(-dot(gi.light.dir, viewDir), 0, 1), fSubsurfaceRough);
s.Emission *= (gi.indirect.diffuse * _SubsurfaceIndirect + gi.light.color * fSubsurface);
#endif
return LightingStandard(s, viewDir, gi);
}

void LightingSTCShaderSubsurface_GI(inout SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi){
#ifdef EFFECT_BILLBOARD
data.atten = lerp(data.atten, 1.0, _BillboardShadowFade); // fade off the shadows on billboards to avoid artifacts
#endif
LightingStandard_GI(s, data, gi);
}

half4 LightingSTCShaderSubsurface_Deferred(SurfaceOutputStandard s, half3 viewDir, UnityGI gi, out half4 outGBuffer0, out half4 outGBuffer1, out half4 outGBuffer2){
#ifdef EFFECT_SUBSURFACE
half fSubsurfaceRough = 0.7 - s.Smoothness * 0.5;
fSubsurfaceRough *= _SubsurfaceRough;
half fSubsurface = GGXTerm(clamp(-dot(gi.light.dir, viewDir), 0, 1), fSubsurfaceRough);
s.Emission *= (gi.indirect.diffuse * _SubsurfaceIndirect + fSubsurface);
#endif
return LightingStandard_Deferred(s, viewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  surface shader


void STCShaderSurf(Input IN, inout SurfaceOutputStandard OUT){

half4 diffuseColor = tex2D(_MainTex, IN.uv_MainTex);

// transparency
OUT.Alpha = diffuseColor.a * IN.color.a;
clip(OUT.Alpha - _Cutoff);

// hue variation
#ifdef EFFECT_HUE_VARIATION
half3 shiftedColor = lerp(diffuseColor, _HueVariationColor.rgb, IN.color.g);
half maxBase = max(diffuseColor.r, max(diffuseColor.g, diffuseColor.b));
half newMaxBase = max(shiftedColor.r, max(shiftedColor.g, shiftedColor.b));
maxBase /= newMaxBase;
maxBase = maxBase * 0.5f + 0.5f;
shiftedColor.rgb *= maxBase;
diffuseColor.rgb = saturate(shiftedColor);
#endif

// color tuning
#ifdef COLOR_TUNING
float Lum = dot(diffuseColor, float3(0.2126, 0.7152, 0.0722));
half3 colorTun = lerp(Lum.xxx, diffuseColor, _Saturation);
colorTun *= _Brightness;
colorTun = (colorTun - 0.5) * _Contrast + 0.5;
diffuseColor = half4(colorTun, diffuseColor.a);
#endif

// albedo end
OUT.Albedo = diffuseColor * _Color;

// normal
#ifdef EFFECT_BUMP
fixed3 normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
normal.x *= _IntensityNm;
normal.y *= _IntensityNm;
OUT.Normal = normalize(normal);
#elif defined(EFFECT_BACKSIDE_NORMALS) || defined(EFFECT_BILLBOARD)
OUT.Normal = float3(0, 0, 1);
#endif

// flip normal on backsides
#ifdef EFFECT_BACKSIDE_NORMALS
if (IN.facing < 0.5){
OUT.Normal.z = -OUT.Normal.z;
}
#endif

// adjust billboard normals to improve GI and matching
#ifdef EFFECT_BILLBOARD
OUT.Normal.z *= 0.5;
OUT.Normal = normalize(OUT.Normal);
#endif

// extra
#ifdef EFFECT_EXTRATEX
fixed4 extra = tex2D(_ExtraTex, IN.uv_MainTex);
half extraR = (extra.r - 0.5) * _SmoothnessStrength + 0.5;
OUT.Smoothness = extraR * _SmoothnessInts;
half extraG = (extra.g - 0.5) * _MetallicStrength + 0.5;
OUT.Metallic = extraG;
half extraB = ((extra.b * IN.color.r) - 0.5) * _OcclusionStrength + 0.5;
OUT.Occlusion = extraB;
#else
OUT.Smoothness = _Glossiness;
OUT.Metallic = _Metallic;
OUT.Occlusion = IN.color.r;
#endif

// subsurface (hijack emissive)
#ifdef EFFECT_SUBSURFACE
OUT.Emission = tex2D(_SubsurfaceTex, IN.uv_MainTex) * _SubsurfaceColor;
#endif

}
