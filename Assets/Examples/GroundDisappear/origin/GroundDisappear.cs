using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GroundDisappear : MonoBehaviour
{
    public Vector4[] StartPosArray;
    private Material mat;

    // Start is called before the first frame update
    void Start()
    {
        mat = GetComponent<MeshRenderer>().sharedMaterial;
    }

    // Update is called once per frame
    void Update()
    {
        mat.SetVectorArray("StartPosArray", StartPosArray);
        mat.SetInt("StartPosCount", StartPosArray.Length);
    }
}
