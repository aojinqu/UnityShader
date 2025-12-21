using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Water : MonoBehaviour
{
    [Header("水的颜色过渡")]
    public Gradient WaterGradient01;
    public Gradient WaterGradient02;

    public Texture2D RampTexture;

    private const int RampWidth = 512;
    private const int RampHeight = 2;

    void OnEnable()
    {
        ApplyRampTexture();
    }

    void OnValidate()
    {
        ApplyRampTexture();
    }

    private void ApplyRampTexture()
    {
        if (WaterGradient01 == null || WaterGradient02 == null)
            return;

        if (RampTexture == null || RampTexture.width != RampWidth || RampTexture.height != RampHeight)
        {
            RampTexture = new Texture2D(RampWidth, RampHeight, TextureFormat.RGBA32, false, false);
            RampTexture.name = "WaterRampTexture (Generated)";
            RampTexture.wrapMode = TextureWrapMode.Clamp;
            RampTexture.filterMode = FilterMode.Bilinear;
            RampTexture.hideFlags = HideFlags.DontSaveInEditor | HideFlags.DontSaveInBuild;
        }

        int count = RampTexture.width * RampTexture.height;
        Color[] cols = new Color[count];

        // Unity 的 SetPixels 数组是按行（从 y=0 底部开始）依次填充：
        // 0~width-1 -> y=0； width~2*width-1 -> y=1
        for (int x = 0; x < RampWidth; x++)
        {
            float t = (float)x / (RampWidth - 1);
            cols[x] = WaterGradient01.Evaluate(t);                 // y = 0（底行）
            cols[x + RampWidth] = WaterGradient02.Evaluate(t);    // y = 1（顶行）
        }

        RampTexture.SetPixels(cols);
        RampTexture.Apply(false, false);

        Shader.SetGlobalTexture("_RampTexture", RampTexture);
    }
}
