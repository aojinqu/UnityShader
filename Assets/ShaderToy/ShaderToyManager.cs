using System.Collections;
using System.Collections.Generic;
using UnityEngine;
//编辑器模式下也可以运行
[ExecuteInEditMode]
public class ShaderToyManager : MonoBehaviour
{
    private Material mat;
    public Shader PostProcessingShader;
    [Range(0, 1)] public float Value;  //制作滑杆

    public Material Mat
    {
        get
        {
            if (PostProcessingShader == null)
            {
                Debug.LogError("未指定Shader!");
                return null;
            }
            else if (!PostProcessingShader.isSupported)
            {
                Debug.LogError("Shader 不支持");
                return null;

            }
            if (mat == null)//这段是为了防止每一帧都生成一个新的材质球
            {
                //将shader直接包装成材质球(可以直接用声明material的形式)
                Material _newMat = new Material(PostProcessingShader);
                _newMat.hideFlags = HideFlags.HideAndDontSave;//不保存材质球，用完就删掉
                mat = _newMat;
            }
            return mat;
        }
    }
    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        //若要修改材质中的变量，需要再Blit之前就修改
        Mat.SetFloat("_Value", Value);
        Graphics.Blit(src, dst, Mat);
    }
}
