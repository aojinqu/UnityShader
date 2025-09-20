using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateSelf : MonoBehaviour
{
    public float speed = 0;
    public GameObject character;
    public enum RotateDirection
    {
        Y轴正方向,
        Y轴负方向,
        X轴正方向,
        X轴负方向,
        Z轴正方向,
        Z轴负方向
    }
    private static readonly Vector3[] directionVectors =
    {
        Vector3.up,         // Y轴正方向
        Vector3.down,       // Y轴负方向        
        Vector3.right,      // X轴正方向
        Vector3.left,       // X轴负方向
        Vector3.forward,    // Z轴正方向
        Vector3.back        // Z轴负方向
    };
    private Vector3 rotationDirection;
    public RotateDirection dir;
    void Start()
    {
    }

    void Update()
    {
        rotationDirection = directionVectors[(int)dir];
        character.transform.Rotate(rotationDirection, speed);

    }
}
