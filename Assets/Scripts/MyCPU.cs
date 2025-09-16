using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MyCPU : MonoBehaviour
{
    [Header("生成的对象")]
    public GameObject Prefab;
    [Header("生成的数量")]
    public int Count=2;
    [Header("生成的范围")]
    public float Range=10;
    // Start is called before the first frame update
    void Start()
    {
        //Prefab = GameObject.Find("Tree01");

        for (int i = 0; i < Count; i++)
        {
            Vector2 pos = Random.insideUnitCircle * Range;//生成单位圆
            GameObject tree = Instantiate(Prefab, new Vector3(pos.x, -5, pos.y), Quaternion.identity);//自动生成，并有一定角度的旋转

            //随机生成颜色
            Color newCol = new Color(Random.value, Random.value, Random.value, Random.value);

            //使用材质属性块:先声明，然后把要赋的类型给材质属性块，最后重新设置gameobject的材质属性块
            MaterialPropertyBlock prop = new MaterialPropertyBlock();
            prop.SetColor("_Color", newCol);
            tree.GetComponentInChildren<MeshRenderer>().SetPropertyBlock(prop);
            
            //会给每个生成的object都分配一次颜色然后通过不同的批次实现，非常耗费资源
            //tree.GetComponent<MeshRenderer>().material.SetColor("_Color", newCol);
        }
    }


}
