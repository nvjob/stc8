// Copyright (c) 2016 Unity Technologies. MIT license - license_unity.txt
// #NVJOB STC8. MIT license - license_nvjob.txt
// #NVJOB STC8 V3.2 - https://nvjob.github.io/unity/nvjob-stc-8
// #NVJOB Nicholas Veselov - https://nvjob.github.io


using System.Collections.Generic;
using System.Linq;
using UnityEngine;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


namespace UnityEditor
{
    [CanEditMultipleObjects]
    internal class STC8Material : MaterialEditor
    {
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        Color smLineColor = Color.HSVToRGB(0, 0, 0.55f), bgLineColor = Color.HSVToRGB(0, 0, 0.3f);
        int smLinePadding = 20, bgLinePadding = 35;
        bool billboard;


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        public override void OnInspectorGUI()
        {
            //--------------

            SetDefaultGUIWidths();
            serializedObject.Update();
            SerializedProperty shaderFind = serializedObject.FindProperty("m_Shader");
            if (!isVisible || shaderFind.hasMultipleDifferentValues || shaderFind.objectReferenceValue == null) return;

            //--------------

            List<MaterialProperty> allProps = new List<MaterialProperty>(GetMaterialProperties(targets));

            //--------------

            EditorGUI.BeginChangeCheck();
            Header();

            //--------------

            EditorGUILayout.LabelField("Geometry:", EditorStyles.boldLabel);
            DrawUILine(smLineColor, 1, smLinePadding);
            GeometryTypeCH(allProps);
            DrawUILine(bgLineColor, 2, bgLinePadding);

            //--------------

            EditorGUILayout.LabelField("Texture and Color Settings:", EditorStyles.boldLabel);
            DrawUILine(smLineColor, 1, smLinePadding);
            MainTexture(allProps);
            ExtraMaps(allProps);
            Subsurface(allProps);


            BumpMap(allProps);
            DrawUILine(bgLineColor, 2, bgLinePadding);

            //--------------

            EditorGUILayout.LabelField("Color and Light Tuning:", EditorStyles.boldLabel);
            DrawUILine(smLineColor, 1, smLinePadding);
            ColorLightTuning(allProps);
            DrawUILine(bgLineColor, 2, bgLinePadding);

            //--------------

            EditorGUILayout.LabelField("Wind Settings:", EditorStyles.boldLabel);
            DrawUILine(smLineColor, 1, smLinePadding);
            WindSettings(allProps);

            //--------------

            Information();
            RenderQueueField();
            EnableInstancingField();
            DoubleSidedGIField();
            EditorGUILayout.Space();
            EditorGUILayout.Space();

            //-------------- 
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void GeometryTypeCH(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty billboardShadowFade = allProps.Find(prop => prop.name == "_BillboardShadowFade");
            MaterialProperty culling = allProps.Find(prop => prop.name == "_Cull");
            MaterialProperty alphaCutoff = allProps.Find(prop => prop.name == "_Cutoff");

            //--------------

            IEnumerable<bool> enableBillboard = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_BILLBOARD"));

            if (enableBillboard != null && billboardShadowFade != null)
            {
                allProps.Remove(billboardShadowFade);

                bool? enable = EditorGUILayout.Toggle("Billboard", enableBillboard.First());

                if (enableBillboard.First())
                {
                    ShaderProperty(billboardShadowFade, billboardShadowFade.displayName);
                    billboard = true;
                }
                else billboard = false;

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_BILLBOARD");
                        else m.DisableKeyword("EFFECT_BILLBOARD");
                    }
                }
            }

            //-------------- 

            if (culling != null)
            {
                allProps.Remove(culling);
                ShaderProperty(culling, culling.displayName);
            }

            //--------------

            if (alphaCutoff != null)
            {
                allProps.Remove(alphaCutoff);
                ShaderProperty(alphaCutoff, alphaCutoff.displayName);
            }

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void MainTexture(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty mainTex = allProps.Find(prop => prop.name == "_MainTex");
            MaterialProperty hueVariation = allProps.Find(prop => prop.name == "_HueVariationColor");
            MaterialProperty colorMat = allProps.Find(prop => prop.name == "_Color");

            //--------------

            if (mainTex != null)
            {
                allProps.Remove(mainTex);
                ShaderProperty(mainTex, mainTex.displayName);
            }

            //--------------

            IEnumerable<bool> enableHueVariation = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_HUE_VARIATION"));

            if (enableHueVariation != null && hueVariation != null)
            {
                allProps.Remove(hueVariation);
                bool? enable = EditorGUILayout.Toggle("Hue Variation", enableHueVariation.First());
                if (enableHueVariation.First()) ShaderProperty(hueVariation, hueVariation.displayName);
                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_HUE_VARIATION");
                        else m.DisableKeyword("EFFECT_HUE_VARIATION");
                    }
                }
            }

            //--------------

            if (colorMat != null)
            {
                allProps.Remove(colorMat);
                ShaderProperty(colorMat, colorMat.displayName);
            }

            //--------------

            DrawUILine(smLineColor, 1, smLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void ExtraMaps(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty extraTex = allProps.Find(prop => prop.name == "_ExtraTex");
            MaterialProperty smoothnessStrength = allProps.Find(prop => prop.name == "_SmoothnessStrength");
            MaterialProperty smoothnessInts = allProps.Find(prop => prop.name == "_SmoothnessInts");
            MaterialProperty metallicStrength = allProps.Find(prop => prop.name == "_MetallicStrength");
            MaterialProperty occlusionStrength = allProps.Find(prop => prop.name == "_OcclusionStrength");
            MaterialProperty glossiness = allProps.Find(prop => prop.name == "_Glossiness");
            MaterialProperty metallic = allProps.Find(prop => prop.name == "_Metallic");

            //--------------

            IEnumerable<bool> enableExtra = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_EXTRATEX"));

            if (enableExtra != null && extraTex != null && glossiness != null && metallic != null && smoothnessStrength != null && smoothnessInts != null && metallicStrength != null && occlusionStrength != null)
            {
                allProps.Remove(extraTex);
                allProps.Remove(smoothnessStrength);
                allProps.Remove(smoothnessInts);
                allProps.Remove(metallicStrength);
                allProps.Remove(occlusionStrength);
                allProps.Remove(glossiness);
                allProps.Remove(metallic);

                bool? enable = EditorGUILayout.Toggle("Extra Maps (Smoothness, Metallic, AO)", enableExtra.First());

                if (enableExtra.First())
                {
                    ShaderProperty(extraTex, extraTex.displayName);
                    ShaderProperty(smoothnessStrength, smoothnessStrength.displayName);
                    ShaderProperty(smoothnessInts, smoothnessInts.displayName);
                    ShaderProperty(metallicStrength, metallicStrength.displayName);
                       ShaderProperty(occlusionStrength, occlusionStrength.displayName);
                }
                else
                {
                    ShaderProperty(glossiness, glossiness.displayName);
                    ShaderProperty(metallic, metallic.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_EXTRATEX");
                        else m.DisableKeyword("EFFECT_EXTRATEX");
                    }
                }
            }

            //--------------

            DrawUILine(smLineColor, 1, smLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void Subsurface(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty subsurfaceTex = allProps.Find(prop => prop.name == "_SubsurfaceTex");
            MaterialProperty subsurfaceColor = allProps.Find(prop => prop.name == "_SubsurfaceColor");
            MaterialProperty subsurfaceIndirect = allProps.Find(prop => prop.name == "_SubsurfaceIndirect");
            MaterialProperty subsurfaceRough = allProps.Find(prop => prop.name == "_SubsurfaceRough");

            //--------------

            IEnumerable<bool> enableSubsurface = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_SUBSURFACE"));

            if (enableSubsurface != null && subsurfaceTex != null && subsurfaceColor != null && subsurfaceIndirect != null && subsurfaceRough != null)
            {
                allProps.Remove(subsurfaceTex);
                allProps.Remove(subsurfaceColor);
                allProps.Remove(subsurfaceIndirect);
                allProps.Remove(subsurfaceRough);

                bool? enable = EditorGUILayout.Toggle("Subsurface (Emissive)", enableSubsurface.First());

                if (enableSubsurface.First())
                {
                    ShaderProperty(subsurfaceTex, subsurfaceTex.displayName);
                    ShaderProperty(subsurfaceColor, subsurfaceColor.displayName);
                    ShaderProperty(subsurfaceIndirect, subsurfaceIndirect.displayName);
                    ShaderProperty(subsurfaceRough, subsurfaceRough.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_SUBSURFACE");
                        else m.DisableKeyword("EFFECT_SUBSURFACE");
                    }
                }
            }

            //--------------

            DrawUILine(smLineColor, 1, smLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void BumpMap(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty bumpMap = allProps.Find(prop => prop.name == "_BumpMap");
            MaterialProperty nntensityNm = allProps.Find(prop => prop.name == "_IntensityNm");

            //--------------

            IEnumerable<bool> enableBump = targets.Select(t => ((Material)t).shaderKeywords.Contains("EFFECT_BUMP"));

            if (enableBump != null && bumpMap != null && nntensityNm != null)
            {
                allProps.Remove(bumpMap);
                allProps.Remove(nntensityNm);

                bool? enable = EditorGUILayout.Toggle("Normal Map", enableBump.First());

                if (enableBump.First())
                {
                    ShaderProperty(bumpMap, bumpMap.displayName);
                    ShaderProperty(nntensityNm, nntensityNm.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("EFFECT_BUMP");
                        else m.DisableKeyword("EFFECT_BUMP");
                    }
                }
            }

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void ColorLightTuning(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty brightness = allProps.Find(prop => prop.name == "_Brightness");
            MaterialProperty saturation = allProps.Find(prop => prop.name == "_Saturation");
            MaterialProperty contrast = allProps.Find(prop => prop.name == "_Contrast");

            //--------------

            IEnumerable<bool> enablColorTun = targets.Select(t => ((Material)t).shaderKeywords.Contains("COLOR_TUNING"));

            if (enablColorTun != null && brightness != null && saturation != null && contrast != null)
            {
                allProps.Remove(brightness);
                allProps.Remove(saturation);
                allProps.Remove(contrast);

                bool? enable = EditorGUILayout.Toggle("Enable Tuning", enablColorTun.First());

                if (enablColorTun.First())
                {
                    ShaderProperty(brightness, brightness.displayName);
                    ShaderProperty(saturation, saturation.displayName);
                    ShaderProperty(contrast, contrast.displayName);
                }

                if (enable != null)
                {
                    foreach (Material m in targets.Cast<Material>())
                    {
                        if (enable.Value) m.EnableKeyword("COLOR_TUNING");
                        else m.DisableKeyword("COLOR_TUNING");
                    }
                }
            }

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void WindSettings(List<MaterialProperty> allProps)
        {
            //--------------

            MaterialProperty windQuality = allProps.Find(prop => prop.name == "_WindQuality");            

            float windType = windQuality.floatValue;
            if (billboard == true && windType > 1) windType = 1;

            if (windQuality != null)
            {
                allProps.Remove(windQuality);
                ShaderProperty(windQuality, windQuality.displayName);
            }

            //--------------

            MaterialProperty windSpeed = allProps.Find(prop => prop.name == "_WindSpeed");
            MaterialProperty windAmplitude = allProps.Find(prop => prop.name == "_WindAmplitude");
            MaterialProperty windDegreeSlope = allProps.Find(prop => prop.name == "_WindDegreeSlope");

            if (windSpeed != null)
            {
                allProps.Remove(windSpeed);
                if (windType >= 1) ShaderProperty(windSpeed, windSpeed.displayName);
            }

            if (windAmplitude != null)
            {
                allProps.Remove(windAmplitude);
                if (windType >= 1) ShaderProperty(windAmplitude, windAmplitude.displayName);
            }

            if (windDegreeSlope != null)
            {
                allProps.Remove(windDegreeSlope);
                if (windType >= 1) ShaderProperty(windDegreeSlope, windDegreeSlope.displayName);
            }

            if (windType >= 1 && billboard == false) DrawUILine(smLineColor, 1, smLinePadding);

            //--------------

            MaterialProperty leafRipple = allProps.Find(prop => prop.name == "_LeafRipple");
            MaterialProperty leafRippleSpeed = allProps.Find(prop => prop.name == "_LeafRippleSpeed");
            MaterialProperty leafTumble = allProps.Find(prop => prop.name == "_LeafTumble");
            MaterialProperty leafTumbleSpeed = allProps.Find(prop => prop.name == "_LeafTumbleSpeed");

            if (leafRipple != null)
            {
                allProps.Remove(leafRipple);
                if (windType >= 2 && windType < 5) ShaderProperty(leafRipple, leafRipple.displayName);
            }

            if (leafRippleSpeed != null)
            {
                allProps.Remove(leafRippleSpeed);
                if (windType >= 2 && windType < 5) ShaderProperty(leafRippleSpeed, leafRippleSpeed.displayName);
            }

            if (leafTumble != null)
            {
                allProps.Remove(leafTumble);
                if (windType == 4) ShaderProperty(leafTumble, leafTumble.displayName);
            }

            if (leafTumbleSpeed != null)
            {
                allProps.Remove(leafTumbleSpeed);
                if (windType == 4) ShaderProperty(leafTumbleSpeed, leafTumbleSpeed.displayName);
            }

            //--------------

            MaterialProperty branchRipple = allProps.Find(prop => prop.name == "_BranchRipple");
            MaterialProperty branchRippleSpeed = allProps.Find(prop => prop.name == "_BranchRippleSpeed");
            MaterialProperty branchWhip = allProps.Find(prop => prop.name == "_BranchWhip");
            MaterialProperty branchTurbulences = allProps.Find(prop => prop.name == "_BranchTurbulences");
            MaterialProperty branchForceHeaviness = allProps.Find(prop => prop.name == "_BranchForceHeaviness");
            MaterialProperty branchHeaviness = allProps.Find(prop => prop.name == "_BranchHeaviness");

            if (branchRipple != null)
            {
                allProps.Remove(branchRipple);
                if (windType >= 3) ShaderProperty(branchRipple, branchRipple.displayName);
            }

            if (branchRippleSpeed != null)
            {
                allProps.Remove(branchRippleSpeed);
                if (windType >= 3) ShaderProperty(branchRippleSpeed, branchRippleSpeed.displayName);
            }

            if (branchWhip != null)
            {
                allProps.Remove(branchWhip);
                if (windType == 5) ShaderProperty(branchWhip, branchWhip.displayName);
            }

            if (branchTurbulences != null)
            {
                allProps.Remove(branchTurbulences);
                if (windType == 5) ShaderProperty(branchTurbulences, branchTurbulences.displayName);
            }

            if (branchForceHeaviness != null)
            {
                allProps.Remove(branchForceHeaviness);
                if (windType == 5) ShaderProperty(branchForceHeaviness, branchForceHeaviness.displayName);
            }

            if (branchHeaviness != null)
            {
                allProps.Remove(branchHeaviness);
                if (windType == 5) ShaderProperty(branchHeaviness, branchHeaviness.displayName);
            }

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void Header()
        {
            //--------------

            EditorGUILayout.Space();
            EditorGUILayout.Space();
            GUIStyle guiStyle = new GUIStyle();
            guiStyle.fontSize = 17;
            EditorGUILayout.LabelField("#NVJOB STC 8 (v3.2)", guiStyle);
            DrawUILine(bgLineColor, 2, bgLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        void Information()
        {
            //--------------

            DrawUILine(bgLineColor, 2, bgLinePadding);
            if (GUILayout.Button("Description and Instructions")) Help.BrowseURL("https://nvjob.github.io/unity/nvjob-stc-8");
            if (GUILayout.Button("#NVJOB Store")) Help.BrowseURL("https://nvjob.github.io/store/");
            DrawUILine(bgLineColor, 2, bgLinePadding);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        public static void DrawUILine(Color color, int thickness = 2, int padding = 10)
        {
            //--------------

            Rect line = EditorGUILayout.GetControlRect(GUILayout.Height(padding + thickness));
            line.height = thickness;
            line.y += padding / 2;
            line.x -= 2;
            EditorGUI.DrawRect(line, color);

            //--------------
        }


        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
}
