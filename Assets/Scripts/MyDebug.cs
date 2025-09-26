using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//用于调试shader中的参数并将其输出
public class MyDebug : MonoBehaviour
{
    public GameObject Monster;
    private Material mMat;
    void Start()
    {
        //Monster = GameObject.Find("Plane");

        mMat = Monster.GetComponentInChildren<MeshRenderer>().sharedMaterial;


    }

    // Update is called once per frame
    void Update()
    {
        float test = mMat.GetFloat("_FPS");
        Debug.Log(test);
    }
}
