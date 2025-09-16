using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MyMonsterShader : MonoBehaviour
{
    #region [变量类型]  //没啥用 纯分块
    //声明的数据类型会被展示到面板上去
    public GameObject MyMonster;
    private Material mat;
    #endregion
    // Start is called before the first frame update
    void Start()
    {
        //Initiate to get gameobject and shared material.
        MyMonster = GameObject.Find("Character01");
        //Debug.Log(MyMonster.transform);
        SkinnedMeshRenderer mr = MyMonster.GetComponentInChildren<SkinnedMeshRenderer>();
        mat = mr.sharedMaterial;
    }

    // Update is called once per frame
    void Update()
    {

    }
    void OnGUI()
    {
        if (GUI.Button(new Rect(40, 10, 150, 50), "受击"))
        {
            StopAllCoroutines();
            StartCoroutine(getAtacked());
        }
        else if (GUI.Button(new Rect(40, 80, 150, 50), "灼烧"))
        {
            StopAllCoroutines();
            StartCoroutine(getFired(2.0f));
        }
        else if (GUI.Button(new Rect(40, 150, 150, 50), "死亡"))
        {
            StopAllCoroutines();
            StartCoroutine(getDead(2.0f));
        }
    }
    IEnumerator getAtacked()
    {
        SkinnedMeshRenderer mr = MyMonster.GetComponentInChildren<SkinnedMeshRenderer>();
        //需要明确：获取的是单个材质还是应用在所有物体上的材质
        //需要明确：获取的变量类型
        //需要明确：获取的变量名称
        mat.SetColor("_Color", Color.white);
        yield return new WaitForSeconds(0.08f);
        mat.SetColor("_Color", Color.black);
    }
    //实现逐帧调用
    IEnumerator getFired(float time)
    {
        float _time = 0;
        while (true)
        {
            _time += Time.deltaTime;//每一帧的时间
            yield return new WaitForEndOfFrame(); //每一帧时停

            if (_time >= time)  //大于2s就退出循环
                yield break;//退出协程也需要用yield（等价于while中写）

            Color _color = Color.Lerp(Color.red, Color.black, _time / time);//在两秒内从黑变红，可以用插值制作需要的效果
            mat.SetColor("_Color", _color);
        }

    }
    //溶解效果
    IEnumerator getDead(float time)
    {
        float _time = 0;
        while (true)
        {
            yield return new WaitForEndOfFrame();
            _time += Time.deltaTime;
            if (_time >= time)
            {
                mat.SetFloat("_Clip", 0f);
                //mat.DisableKeyword("_DISSOLVEENABLED_ON");
                yield break;

            }

            mat.EnableKeyword("_DISSOLVEENABLED_ON");//控制材质面板开关Toggle，需要和subshader中声明的一致
            mat.SetFloat("_Clip", _time / time);
        }

    }
}
