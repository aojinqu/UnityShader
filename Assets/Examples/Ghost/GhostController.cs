using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.TextCore.Text;
using UnityEngine.UI;

public class GhostController : MonoBehaviour
{
    public GameObject character;
    public Button SetColorBtn;
    public Toggle toggle01;
    public Slider rotateSlider;
    public Slider repeatXSlider;
    public Slider repeatYSlider;

    private Material mat;
    void Start()
    {
        mat = character.GetComponentInChildren<SkinnedMeshRenderer>().sharedMaterial;
        SetColorBtn.onClick.AddListener(OnSetColorBtn);
        toggle01.onValueChanged.AddListener(OnToggle01);
        rotateSlider.onValueChanged.AddListener(OnrotateSlider);
        repeatXSlider.onValueChanged.AddListener(AnimationXSlider);
        repeatYSlider.onValueChanged.AddListener(AnimationYSlider);

    }

    // Update is called once per frame
    void Update()
    {

    }
    void OnSetColorBtn()
    {
        float r = Random.value;
        float g = Random.value;
        float b = Random.value;
        mat.SetColor("_FresnelColor", new Color(r, g, b));
    }
    #region [实现]
    void OnToggle01(bool isOn)
    {
        character.SetActive(isOn);
    }
    void OnrotateSlider(float value)
    {
        character.GetComponent<RotateSelf>().speed = value;
    }
    void AnimationXSlider(float value)
    {
        Vector4 _animation = mat.GetVector("_Animation");
        mat.SetVector("_Animation", new Vector4(value, _animation.y, _animation.z, _animation.w));
    }
    void AnimationYSlider(float value)
    {
        Vector4 _animation = mat.GetVector("_Animation");
        mat.SetVector("_Animation", new Vector4(_animation.x, value, _animation.z, _animation.w));

    }
    #endregion
}
