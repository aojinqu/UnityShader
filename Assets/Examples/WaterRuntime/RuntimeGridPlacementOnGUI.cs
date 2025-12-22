using System.Collections.Generic;
using UnityEngine;

namespace WaterRuntime
{
    /// <summary>
    /// 运行时（Play Mode）用的简单网格选择 + 生成物体面板：
    /// - 点击“显示/隐藏”切换面板与网格预览
    /// - 在面板里点格子确定行列
    /// - 点击按钮在该格子中心生成一个物体（RuntimeWaterGridController.placePrefab）
    ///
    /// 适合快速做出你截图里的“展开地块位置→选行列→生成物体”的效果，不依赖额外 UGUI 搭建。
    /// </summary>
    [DisallowMultipleComponent]
    public class RuntimeGridPlacementOnGUI : MonoBehaviour
    {
        [Header("引用")]
        public RuntimeWaterGridController controller;

        [Header("显示控制")]
        public bool show = true;
        public bool showGridPreview = true;

        [Header("网格预览外观")]
        [Tooltip("预览块Y偏移，避免和地面Z-fighting。")]
        public float previewYOffset = 0.02f;

        [Range(0.1f, 1f)]
        [Tooltip("预览块相对格子尺寸的缩放（1=铺满整个格子）。")]
        public float previewSizeFactor = 0.92f;

        public Color previewColor = new Color(0f, 0.6f, 1f, 0.35f);
        public Color selectedColor = new Color(0.2f, 1f, 0.2f, 0.6f);

        [Header("面板布局")]
        public Rect windowRect = new Rect(20, 20, 520, 420);

        private Vector2Int selectedCell = new Vector2Int(0, 0);
        private int inputCols;
        private int inputRows;

        private GameObject previewRoot;
        private readonly Dictionary<Vector2Int, Renderer> cellPreviewRenderers = new Dictionary<Vector2Int, Renderer>();
        private Material previewMaterial;

        private void Awake()
        {
            if (controller)
            {
                inputCols = controller.gridSize.x;
                inputRows = controller.gridSize.y;
            }
        }

        private void OnEnable()
        {
            EnsurePreviewMaterial();
        }

        private void OnDisable()
        {
            DestroyPreview();
        }

        private void Update()
        {
            if (!controller)
            {
                return;
            }

            if (show && showGridPreview)
            {
                EnsurePreview();
                RefreshPreviewColors();
            }
            else
            {
                DestroyPreview();
            }
        }

        private void OnGUI()
        {
            // 右上角一个小按钮，随时可切换显示/隐藏
            const float toggleW = 80f;
            const float toggleH = 36f;
            var toggleRect = new Rect(Screen.width - toggleW - 18f, 18f, toggleW, toggleH);
            if (GUI.Button(toggleRect, show ? "隐藏" : "显示"))
            {
                show = !show;
            }

            if (!show)
            {
                return;
            }

            windowRect = GUI.Window(GetInstanceID(), windowRect, DrawWindow, "地块选择");
        }

        private void DrawWindow(int id)
        {
            if (!controller)
            {
                GUILayout.Label("未绑定 RuntimeWaterGridController。");
                GUI.DragWindow();
                return;
            }

            // 行列输入
            GUILayout.BeginHorizontal();
            GUILayout.Label("列", GUILayout.Width(26));
            inputCols = Mathf.Max(1, IntField(inputCols, 52));
            GUILayout.Space(10);
            GUILayout.Label("行", GUILayout.Width(26));
            inputRows = Mathf.Max(1, IntField(inputRows, 52));
            GUILayout.Space(10);

            if (GUILayout.Button("Apply", GUILayout.Width(80)))
            {
                controller.gridSize = new Vector2Int(inputCols, inputRows);
                selectedCell = new Vector2Int(
                    Mathf.Clamp(selectedCell.x, 0, controller.gridSize.x - 1),
                    Mathf.Clamp(selectedCell.y, 0, controller.gridSize.y - 1)
                );
                RebuildPreview();
            }

            if (GUILayout.Button("Clear", GUILayout.Width(80)))
            {
                controller.ClearPlacedObjects();
            }
            GUILayout.EndHorizontal();

            GUILayout.Space(8);

            // 预览开关
            GUILayout.BeginHorizontal();
            showGridPreview = GUILayout.Toggle(showGridPreview, "展开地块位置（预览）", GUILayout.Width(160));
            GUILayout.FlexibleSpace();
            GUILayout.Label($"当前选择：行 {selectedCell.y}  列 {selectedCell.x}");
            GUILayout.EndHorizontal();

            GUILayout.Space(8);

            // 格子选择区域
            DrawGridSelector();

            GUILayout.Space(8);

            // 操作按钮
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("在选中地块生成物体", GUILayout.Height(32)))
            {
                controller.PlaceObject(selectedCell);
            }
            if (GUILayout.Button("切换水块（可选）", GUILayout.Height(32)))
            {
                controller.ToggleCell(selectedCell.x, selectedCell.y);
            }
            GUILayout.EndHorizontal();

            // 拖拽窗口
            GUI.DragWindow();
        }

        private void DrawGridSelector()
        {
            var cols = Mathf.Max(1, controller.gridSize.x);
            var rows = Mathf.Max(1, controller.gridSize.y);

            // 让按钮尽量方形
            float cellSize = 26f;
            float maxWidth = windowRect.width - 24f;
            float trySize = Mathf.Floor((maxWidth - (cols - 1) * 2f) / cols);
            cellSize = Mathf.Clamp(trySize, 18f, 34f);

            var oldBg = GUI.backgroundColor;

            for (int r = 0; r < rows; r++)
            {
                GUILayout.BeginHorizontal();
                for (int c = 0; c < cols; c++)
                {
                    bool isSelected = (selectedCell.x == c && selectedCell.y == r);
                    GUI.backgroundColor = isSelected ? new Color(0.2f, 1f, 0.2f, 0.9f) : Color.white;

                    string label = isSelected ? "✓" : "";
                    if (GUILayout.Button(label, GUILayout.Width(cellSize), GUILayout.Height(cellSize)))
                    {
                        selectedCell = new Vector2Int(c, r);
                        RefreshPreviewColors();
                    }
                }
                GUILayout.EndHorizontal();
            }

            GUI.backgroundColor = oldBg;
        }

        private int IntField(int value, int width)
        {
            string s = GUILayout.TextField(value.ToString(), GUILayout.Width(width));
            if (int.TryParse(s, out int parsed))
            {
                return parsed;
            }
            return value;
        }

        private void OnDestroy()
        {
            if (previewMaterial)
            {
                Destroy(previewMaterial);
                previewMaterial = null;
            }
        }

        private void EnsurePreviewMaterial()
        {
            if (previewMaterial)
            {
                return;
            }

            // URP 优先，其次内置 Unlit，再次 Standard
            Shader shader = Shader.Find("Universal Render Pipeline/Unlit");
            if (!shader)
            {
                shader = Shader.Find("Unlit/Color");
            }
            if (!shader)
            {
                shader = Shader.Find("Standard");
            }

            if (shader)
            {
                previewMaterial = new Material(shader);
                previewMaterial.name = "RuntimeGridPreviewMat (Runtime)";
                ApplyColorToMaterial(previewMaterial, previewColor);
            }
        }

        private void EnsurePreview()
        {
            if (!previewRoot)
            {
                previewRoot = new GameObject("RuntimeGridPreviewRoot");
                previewRoot.transform.SetParent(transform, false);
            }

            // 若格子数变化，重建
            int desired = Mathf.Max(1, controller.gridSize.x) * Mathf.Max(1, controller.gridSize.y);
            if (cellPreviewRenderers.Count != desired)
            {
                RebuildPreview();
            }
        }

        private void RebuildPreview()
        {
            DestroyPreview();
            EnsurePreviewMaterial();

            if (!controller)
            {
                return;
            }

            previewRoot = new GameObject("RuntimeGridPreviewRoot");
            previewRoot.transform.SetParent(transform, false);

            int cols = Mathf.Max(1, controller.gridSize.x);
            int rows = Mathf.Max(1, controller.gridSize.y);
            float scale = controller.cellWorldSize * Mathf.Clamp01(previewSizeFactor);

            for (int r = 0; r < rows; r++)
            {
                for (int c = 0; c < cols; c++)
                {
                    var cell = new Vector2Int(c, r);
                    var quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
                    quad.name = $"CellPreview_{c}_{r}";
                    quad.transform.SetParent(previewRoot.transform, false);
                    quad.transform.position = controller.GetCellCenterWorld(cell) + new Vector3(0f, previewYOffset, 0f);
                    quad.transform.rotation = Quaternion.Euler(90f, 0f, 0f);
                    quad.transform.localScale = new Vector3(scale, scale, 1f);

                    // 移除碰撞体，避免挡住射线或物理
                    var col = quad.GetComponent<Collider>();
                    if (col)
                    {
                        Destroy(col);
                    }

                    var renderer = quad.GetComponent<Renderer>();
                    if (renderer && previewMaterial)
                    {
                        renderer.sharedMaterial = previewMaterial;
                    }
                    cellPreviewRenderers[cell] = renderer;
                }
            }

            RefreshPreviewColors();
        }

        private void RefreshPreviewColors()
        {
            if (!previewMaterial)
            {
                return;
            }

            // sharedMaterial 统一时，不能逐格改材质颜色；这里用 per-renderer property block 来做高亮
            foreach (var kv in cellPreviewRenderers)
            {
                var cell = kv.Key;
                var renderer = kv.Value;
                if (!renderer)
                {
                    continue;
                }

                bool isSelected = cell == selectedCell;
                var c = isSelected ? selectedColor : previewColor;

                var mpb = new MaterialPropertyBlock();
                renderer.GetPropertyBlock(mpb);
                ApplyColorToPropertyBlock(mpb, c);
                renderer.SetPropertyBlock(mpb);
            }
        }

        private static void ApplyColorToMaterial(Material mat, Color c)
        {
            if (!mat)
            {
                return;
            }

            // URP Unlit uses _BaseColor; built-in uses _Color
            if (mat.HasProperty("_BaseColor"))
            {
                mat.SetColor("_BaseColor", c);
            }
            if (mat.HasProperty("_Color"))
            {
                mat.SetColor("_Color", c);
            }
        }

        private static void ApplyColorToPropertyBlock(MaterialPropertyBlock mpb, Color c)
        {
            if (mpb == null)
            {
                return;
            }

            mpb.SetColor("_BaseColor", c);
            mpb.SetColor("_Color", c);
        }

        private void DestroyPreview()
        {
            cellPreviewRenderers.Clear();
            if (previewRoot)
            {
                Destroy(previewRoot);
                previewRoot = null;
            }
        }
    }
}


