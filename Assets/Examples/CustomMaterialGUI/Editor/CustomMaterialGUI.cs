using System.Numerics;
using Unity.Mathematics;
using UnityEditor;
using UnityEngine;

public class CustomMaterialGUI : ShaderGUI
{
    MaterialProperty floatProp;
    MaterialProperty vectorProp;
    MaterialProperty colorProp;
    MaterialProperty baseMapProp;
    int vectorX;
    float vectorY,vectorZ,vectorW;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        //base.OnGUI(materialEditor, properties);
        //获取相应属性
        floatProp = FindProperty("_Float", properties);
        vectorProp = FindProperty("_Vector4", properties);
        colorProp = FindProperty("_Color", properties);

        //初始化
        vectorX = (int)vectorProp.vectorValue.x;
        vectorY = vectorProp.vectorValue.y;
        vectorZ = vectorProp.vectorValue.z;
        vectorW = vectorProp.vectorValue.w;
        //绘制相应属性
        materialEditor.FloatProperty(floatProp, "FloatName");
        materialEditor.VectorProperty(vectorProp, "Vector4Name");
        //滑动条版本
        materialEditor.RangeProperty(floatProp, "FloatName");
        //Color
        materialEditor.ColorProperty(colorProp, "Color");


        //Make a text field for entering integers,注意一定要写返回值，不然拿不到这个数重新赋值
        vectorX = EditorGUILayout.IntField("VetcorX", vectorX);
        //滑动条版本 
        vectorY = EditorGUILayout.Slider("VetcorY", vectorY, 0, 1);
        //范围滑动条,注意无返回值
        EditorGUILayout.MinMaxSlider("VectorZW", ref vectorZ, ref vectorW, 0f, 1f);
        //重新赋值给vectorprop材质
        UnityEngine.Vector4 Vector4_new = new UnityEngine.Vector4(vectorX, vectorY, vectorZ, vectorW);
        vectorProp.vectorValue = Vector4_new;

        baseMapProp = FindProperty("_BaseMap", properties);
        materialEditor.TextureProperty(baseMapProp, "纹理(materialEditor)");
        materialEditor.TexturePropertySingleLine(new GUIContent("单行纹理(materialEditor)"), baseMapProp);
        materialEditor.TexturePropertyTwoLines(new GUIContent("两行纹理(materialEditor)"), baseMapProp, colorProp, new GUIContent("第二行属性"), vectorProp);

    }
}
