using UnityEngine;

[ExecuteAlways]
public class RaymarchFeed : MonoBehaviour
{
    public Material targetMaterial;
    Camera cam;
    void OnEnable()
    {
        cam = Camera.main;
    }

    void Update()
    {
        if (targetMaterial == null) return;

        // Resolution (in pixels)
        Vector2 res = new Vector2(Screen.width, Screen.height);
        targetMaterial.SetVector("_Resolution", new Vector4(res.x, res.y, 0, 0));

        // Mouse: pass pixel coordinates; if no button pressed we can pass (-1,-1)
        Vector3 m = Input.mousePosition;
        if (m == null) m = Vector3.zero;
        targetMaterial.SetVector("_Mouse", new Vector4(m.x, m.y, Input.GetMouseButton(0) ? 1 : 0, 0));

        // Unity's _Time can be grabbed from Time.time; we pass time in seconds as .y
        float t = Time.time;
        targetMaterial.SetVector("_TimeParams", new Vector4(t / 20.0f, t, t * 2.0f, t * 3.0f));
    }
}
