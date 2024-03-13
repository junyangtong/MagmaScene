// 柏林噪声
float2 radom2(float2 i)
{
    
    i = float2(dot(i,float2(127.1,311.7)),dot(i,float2(269.5,183.3)));
    //return sin(i*6.283 + _Time.y);
    return sin(i+ (_Time.y*0.6))*2.-1.;

}

float noise (float2 uv)
{
    float2 i = floor(uv);
    float2 f = frac(uv);
    
    float a = dot(radom2(i),f);    
    float b = dot(radom2(i + float2(1.0,0.0)),f - float2(1.0,0.0));
    float c = dot(radom2(i + float2(0.0,1.0)),f - float2(0.0,1.0));
    float d = dot(radom2(i + float2(1.0,1.0)),f - float2(1.0,1.0));
    
    // Smooth Interpolation
    float2 u = f*f*(3.-2.*f);
    
    float noise = lerp(lerp(a,b,u.x),lerp(c,d,u.x),u.y);

    return noise;
}

// 计算水面波形
        float _Steepness;
        float _Amplitude;
        float _WaveLength;
        float _WindSpeed;
        float _WindDir;

    struct Wave{
        float3 wavePos;
        float3 waveNormal;
    };
    
    Wave GerstnerWave(float2 posXZ, float amp, float waveLen, float speed, int dir) // 传入的是每一个波形的效果，最后叠加，然后由UI参数统一调控。
    {
        Wave o;
        float w = 2*PI / (waveLen * _WaveLength); 
        float A = amp * _Amplitude;
        float WA = w * A;
        float Q = _Steepness / (WA * 6);
        float dirRad = radians((dir + _WindDir) % 360);
        float2 D = normalize(float2(sin(dirRad), cos(dirRad)));
        float common = w * dot(D, posXZ) + _Time.y * sqrt(9.8 * w) * speed * _WindSpeed;
        float sinC = sin(common);
        float cosC = cos(common);
        o.wavePos.xz = Q * A * D.xy * cosC;
        o.wavePos.y = A * sinC / 6;
        return o;
    }

    // 动态设置曲面细分因子
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