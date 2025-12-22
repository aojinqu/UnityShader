using System.Collections.Generic;
using Bitgem.VFX.StylisedWater;
using UnityEngine;

namespace WaterRuntime
{
    /// <summary>
    /// 负责在运行时按网格生成/移除水体（基于 WaterVolumeBox）。
    /// 挂到一个常驻对象（如场景管理器）上即可。
    /// </summary>
    public class RuntimeWaterGridController : MonoBehaviour
    {
        [Header("网格设置")]
        [Tooltip("网格宽度（X）和长度（Z）。默认 4x4。")]
        public Vector2Int gridSize = new Vector2Int(4, 4);

        [Tooltip("每个格子的世界尺寸（米）。会用于 WaterVolumeBox 的 Dimensions.xz。")]
        public float cellWorldSize = 2f;

        [Tooltip("水体高度（米）。会用于 WaterVolumeBox 的 Dimensions.y。")]
        public float waterHeight = 1f;

        [Tooltip("网格世界原点（左下角）。")]
        public Vector3 gridOrigin = Vector3.zero;

        [Header("StylisedWater 网格精度")]
        [Tooltip("WaterVolumeBase.TileSize（米）。\n- 若希望“一个地块=一个水块”，建议设为 cellWorldSize。\n- 若希望更细的水面网格，可设为更小值（如 0.5）。")]
        public float waterTileSize = 1f;

        [Header("材质 / 着色器")]
        [Tooltip("水面材质，必须兼容 WaterVolume（例如你自定义的 Water.shader 材质）。")]
        public Material waterMaterial;

        [Header("地块生成物体（可选）")]
        [Tooltip("在选中的格子中心生成的物体预制体。")]
        public GameObject placePrefab;

        [Tooltip("生成物体的世界坐标偏移（基于格子中心）。")]
        public Vector3 placeOffset = Vector3.zero;

        [Tooltip("同一格子重复生成时，是否替换旧物体。")]
        public bool replacePlacedObject = true;

        // 已生成的 cell -> 对应的 WaterVolumeBox
        private readonly Dictionary<Vector2Int, WaterVolumeBox> volumes = new Dictionary<Vector2Int, WaterVolumeBox>();

        // 已放置的 cell -> 对应的 GameObject
        private readonly Dictionary<Vector2Int, GameObject> placedObjects = new Dictionary<Vector2Int, GameObject>();

        /// <summary>
        /// 切换某个格子：如果存在则删除，否则创建。
        /// 供 UI 按钮调用。
        /// </summary>
        public void ToggleCell(int gx, int gz)
        {
            var cell = new Vector2Int(gx, gz);
            if (volumes.ContainsKey(cell))
            {
                RemoveCell(cell);
            }
            else
            {
                CreateCell(cell);
            }
        }

        /// <summary>
        /// 返回格子中心点的世界坐标（基于 gridOrigin / cellWorldSize）。
        /// </summary>
        public Vector3 GetCellCenterWorld(int gx, int gz)
        {
            return GetCellCenterWorld(new Vector2Int(gx, gz));
        }

        /// <summary>
        /// 返回格子中心点的世界坐标（基于 gridOrigin / cellWorldSize）。
        /// </summary>
        public Vector3 GetCellCenterWorld(Vector2Int cell)
        {
            return gridOrigin + new Vector3(cell.x * cellWorldSize + cellWorldSize * 0.5f, 0f, cell.y * cellWorldSize + cellWorldSize * 0.5f);
        }

        /// <summary>
        /// 在指定格子中心生成一个物体（placePrefab）。
        /// 默认同一格子会替换旧物体（replacePlacedObject=true）。
        /// </summary>
        public GameObject PlaceObject(int gx, int gz)
        {
            return PlaceObject(new Vector2Int(gx, gz));
        }

        /// <summary>
        /// 在指定格子中心生成一个物体（placePrefab）。
        /// 默认同一格子会替换旧物体（replacePlacedObject=true）。
        /// </summary>
        public GameObject PlaceObject(Vector2Int cell)
        {
            if (!IsCellInRange(cell))
            {
                Debug.LogWarning($"Cell {cell} out of range {gridSize}.");
                return null;
            }

            if (!placePrefab)
            {
                Debug.LogWarning("placePrefab is not set. Please assign a prefab to RuntimeWaterGridController.placePrefab.");
                return null;
            }

            if (placedObjects.TryGetValue(cell, out var existing) && existing)
            {
                if (!replacePlacedObject)
                {
                    return existing;
                }

                Destroy(existing);
            }

            var pos = GetCellCenterWorld(cell) + placeOffset;
            var go = Instantiate(placePrefab, pos, Quaternion.identity, transform);
            go.name = $"{placePrefab.name}_{cell.x}_{cell.y}";
            placedObjects[cell] = go;
            return go;
        }

        /// <summary>
        /// 删除指定格子的已放置物体（如果存在）。
        /// </summary>
        public void RemovePlacedObject(int gx, int gz)
        {
            RemovePlacedObject(new Vector2Int(gx, gz));
        }

        /// <summary>
        /// 删除指定格子的已放置物体（如果存在）。
        /// </summary>
        public void RemovePlacedObject(Vector2Int cell)
        {
            if (!placedObjects.TryGetValue(cell, out var go))
            {
                return;
            }

            placedObjects.Remove(cell);
            if (go)
            {
                Destroy(go);
            }
        }

        /// <summary>
        /// 创建一个指定网格坐标的 WaterVolumeBox。
        /// </summary>
        private void CreateCell(Vector2Int cell)
        {
            // 防御：越界不创建
            if (!IsCellInRange(cell))
            {
                Debug.LogWarning($"Cell {cell} out of range {gridSize}.");
                return;
            }

            var go = new GameObject($"WaterVolume_{cell.x}_{cell.y}");
            go.transform.parent = transform;

            // 计算放置位置：以格子中心为基准
            var pos = GetCellCenterWorld(cell);
            go.transform.position = pos;

            var volume = go.AddComponent<WaterVolumeBox>();

            // 基于 cellWorldSize 设置水体尺寸
            volume.Dimensions = new Vector3(cellWorldSize, waterHeight, cellWorldSize);
            volume.TileSize = Mathf.Max(0.1f, waterTileSize);

            // 确保有 MeshRenderer 并赋材质
            var renderer = go.GetComponent<MeshRenderer>();
            if (!renderer)
            {
                renderer = go.AddComponent<MeshRenderer>();
            }
            if (waterMaterial)
            {
                renderer.sharedMaterial = waterMaterial;
            }
            else
            {
                Debug.LogWarning("Water material is not set. Please assign a material that uses your water shader.");
            }

            // 立即生成网格
            volume.Rebuild();

            volumes[cell] = volume;
        }

        /// <summary>
        /// 删除指定网格坐标的水体。
        /// </summary>
        private void RemoveCell(Vector2Int cell)
        {
            if (!volumes.TryGetValue(cell, out var volume))
            {
                return;
            }

            volumes.Remove(cell);
            if (volume)
            {
                Destroy(volume.gameObject);
            }
        }

        /// <summary>
        /// 如果需要一次性清空所有格子，可以调用。
        /// </summary>
        public void ClearAll()
        {
            foreach (var kv in volumes)
            {
                if (kv.Value)
                {
                    Destroy(kv.Value.gameObject);
                }
            }
            volumes.Clear();
        }

        /// <summary>
        /// 清空所有已放置物体。
        /// </summary>
        public void ClearPlacedObjects()
        {
            foreach (var kv in placedObjects)
            {
                if (kv.Value)
                {
                    Destroy(kv.Value);
                }
            }
            placedObjects.Clear();
        }

        private bool IsCellInRange(Vector2Int cell)
        {
            return cell.x >= 0 && cell.x < gridSize.x && cell.y >= 0 && cell.y < gridSize.y;
        }
    }
}

