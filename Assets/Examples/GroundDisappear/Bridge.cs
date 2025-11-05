using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bridge : MonoBehaviour
{
    public GameObject bridge;

    public Vector4[] StartPosArray;
    private Material mat;

    // Start is called before the first frame update
    void Start()
    {
        bridge = GameObject.Find("Bridge_BuildIn");

        mat = bridge.GetComponent<MeshRenderer>().sharedMaterial;
        mat.SetVectorArray("StartPosArray", StartPosArray);
        mat.SetInt("StartPosCount", StartPosArray.Length);
    }

}
