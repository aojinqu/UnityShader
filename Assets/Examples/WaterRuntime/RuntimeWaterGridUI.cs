using UnityEngine;
using UnityEngine.UI;

namespace WaterRuntime
{
    /// <summary>
    /// 简单的 4x4 按钮面板示例：
    /// - 需要在 Canvas 下创建一个空物体挂这个脚本
    /// - 指定 buttonPrefab（一个含 Button+Text 的预制或子物体）
    /// - 脚本会克隆出 gridSize.x * gridSize.y 个按钮，并绑定 ToggleCell
    /// </summary>
    public class RuntimeWaterGridUI : MonoBehaviour
    {
        [Tooltip("按钮模板：必须包含 Button 组件。会被克隆 4x4 次。")]
        public Button buttonPrefab;

        [Tooltip("水网格控制器引用。")]
        public RuntimeWaterGridController controller;

        private void Start()
        {
            if (!buttonPrefab || !controller)
            {
                Debug.LogWarning("Please assign buttonPrefab and controller.");
                return;
            }

            // 清理模板自身显示
            buttonPrefab.gameObject.SetActive(false);

            // 创建网格按钮
            for (int z = 0; z < controller.gridSize.y; z++)
            {
                for (int x = 0; x < controller.gridSize.x; x++)
                {
                    var btn = Instantiate(buttonPrefab, buttonPrefab.transform.parent);
                    btn.gameObject.name = $"Cell_{x}_{z}";
                    btn.gameObject.SetActive(true);

                    int cx = x;
                    int cz = z;
                    btn.onClick.AddListener(() => controller.ToggleCell(cx, cz));

                    // 如果按钮上有文本，改一下标题方便调试
                    var text = btn.GetComponentInChildren<TMPro.TMP_Text>();
                    if (text)
                    {
                        text.text = $"{cx},{cz}";
                    }
                    else
                    {
                        var legacy = btn.GetComponentInChildren<Text>();
                        if (legacy)
                        {
                            legacy.text = $"{cx},{cz}";
                        }
                    }
                }
            }
        }
    }
}

