
    // 动态设置曲面细分因子
            //不对视锥体以外的三角形细分
            bool TriangleIsBelowClipPlane (float3 p0, float3 p1, float3 p2, int planeIndex, float bias) 
            {
                float4 plane = unity_CameraWorldClipPlanes[planeIndex];
                return
                    dot(float4(p0, 1), plane) < bias &&
                    dot(float4(p1, 1), plane) < bias &&
                    dot(float4(p2, 1), plane) < bias;
            }
            
            bool TriangleIsCulled (float3 p0, float3 p1, float3 p2, float bias) {
                return
                    TriangleIsBelowClipPlane(p0, p1, p2, 0, bias) ||
                    TriangleIsBelowClipPlane(p0, p1, p2, 1, bias) ||
                    TriangleIsBelowClipPlane(p0, p1, p2, 2, bias) ||
                    TriangleIsBelowClipPlane(p0, p1, p2, 3, bias);
            }
            // 随着距相机的距离减少细分数
            float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
            {
                float3 worldPosition = TransformObjectToWorld(vertex.xyz);
                float dist = distance(worldPosition,  GetCameraPositionWS());
                float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
                return (f);
            }