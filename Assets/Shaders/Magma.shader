Shader "Test/Magma"
{
    Properties
    {
        [Header(Magma)]
        [HDR]_MagmaCol1            ("岩浆颜色1", Color) = (1,1,1,1)
        _MagmaCol2            ("岩浆颜色2", Color) = (1,1,1,1)
        _EdgeOffest           ("岩浆边缘范围偏移", Range(-0.1,0.1)) = 0
        _EdgeCol         ("岩浆边缘颜色", Color) = (1,1,1,1)
        [HDR]_RimCol         ("岩浆边缘光颜色", Color) = (1,1,1,1)
        _SmoothThresholdUp    ("边缘着色平滑阈值（向上）", Range(0,0.1)) = 0
        _SmoothThresholdDown    ("边缘着色平滑阈值（向下）", Range(0,0.1)) = 0
        _SmoothThresholdRim    ("着色平滑阈值边缘光", Range(0,0.5)) = 0
        _RimThresholdOffest    ("边缘光范围阈值", Range(-1,1)) = -0.2
        _SpecNoiseSize    ("高光噪声大小XY  强度W", Vector) = (10,0,0,0)
        [HDR]_SpecCol1         ("岩浆高光颜色1", Color) = (1,1,1,1)
        _SpecCol2         ("岩浆高光颜色2", Color) = (1,1,1,1)
        _FlowDir    ("流动方向XY", Vector) = (2,2,0,0)
        
        [Header(Stone)]
        _StoneCol            ("岩石颜色", Color) = (1,1,1,1)
        _DiffRange          ("暗面分割阈值", float) = 1
        _StoneHeight         ("岩石高度", float) = 1
        _YThreshold         ("岩浆平面高度", float) = 1
        _YThresholdOffest   ("岩浆平面高度偏移", Range(0,0.3)) = 0.1
        _StoneThresholdOffest("岩石发光范围阈值", Range(-1,1)) = 0.0
        _StoneSmoothThreshold("岩石发光范围平滑度", Range(-1,1)) = 0.0
        [HDR]_StoneEmissCol         ("岩石自发光颜色", Color) = (1,1,1,1)

        [Header(Texture)]
        _HeightMap          ("置换贴图",2D)    = "white" {}
        _StoneMap          ("岩石颜色贴图",2D)    = "white" {}
        _MagmaMap          ("岩浆底层噪声贴图",2D)    = "white" {}
        _MagmaWarpMap          ("岩浆高光扰动贴图",2D)    = "white" {}
        _NormalMap          ("法线贴图",2D)    = "bump" {}
        
        [Header(Tessellation)]
        _Tess               ("细分程度", Range(1, 32)) = 20
        _MaxTessDistance    ("细分最大距离", Range(1, 320)) = 20
        _MinTessDistance    ("细分最小距离", Range(1, 320)) = 1
        _MagmaThickness     ("岩浆厚度", Range(0,1)) = 0
        [Header(Genstner)]
        _Steepness          ("重力", Range(0,5)) = 0.8
        _Amplitude          ("振幅",Range(0,1)) = 1
        _WaveLength         ("波长",Range(0,5)) = 1
        _WindSpeed          ("风速",Range(0,1)) = 1
        _WindDir            ("风向", Range(0,360)) = 0
        
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry"
        }
        
        Pass
        {
            Name "Pass"
            // Render State
            Cull Back

            HLSLPROGRAM

            #pragma require tessellation
            #pragma require geometry
            
            #pragma vertex BeforeTessVertProgram
            #pragma hull HullProgram
            #pragma domain DomainProgram
            #pragma fragment FragmentProgram

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 4.6

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ Anti_Aliasing_ON

            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
            #include "Assets/Shaders/Common.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float _Tess;
            float _MaxTessDistance;
            float _MinTessDistance;
            float _MagmaThickness;
            
            float4 _StoneCol;
            float4 _MagmaCol1;
            float4 _MagmaCol2;
            float _EdgeOffest;
            float4 _EdgeCol;
            float4 _RimCol;
            float _SmoothThresholdUp;
            float _SmoothThresholdDown;
            float _SmoothThresholdRim;
            float _RimThresholdOffest;
            float4 _SpecNoiseSize;
            float4 _SpecCol1;
            float4 _SpecCol2;
            float4 _FlowDir;
            float _StoneHeight;
            float _YThreshold;
            float _YThresholdOffest;
            float _StoneThresholdOffest;
            float _StoneSmoothThreshold;
            float4 _StoneEmissCol;
            float _DiffRange;
            float4 _MainTexture_Texelsize;
            
            CBUFFER_END
            TEXTURE2D(_HeightMap);
            float4 _HeightMap_ST;
            SAMPLER(sampler_HeightMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_StoneMap);
            float4 _StoneMap_ST;
            TEXTURE2D(_MagmaMap);
            float4 _MagmaMap_ST;
            TEXTURE2D(_MagmaWarpMap);
            SAMPLER(sampler_MagmaWarpMap);
            float4 _MagmaWarpMap_ST;

            // 贴图采样器
            SamplerState smp_Point_Repeat;

            // 顶点着色器的输入
            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float4 tangent  : TANGENT;
            };

            // 片段着色器的输入
            struct Varyings
            {
                float4 color : COLOR;
                float3 nDirWS : NORMAL_WS;
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 posWS:TEXCOORD1;
                float4 scrPos	 :TEXCOORD2;  
                float3 tDirWS : TEXCOORD4;
                float3 bDirWS : TEXCOORD5;
                float3 waveOffset : TEXCOORD6;
                float4 shadowCoord : TEXCOORD7;
                float mask : TEXCOORD8;
                float mask2 : TEXCOORD9;
                float mask3 : TEXCOORD10;
            };

            // 内部因素使用SV_InsideTessFactor语义
            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            // 该结构的其余部分与Attributes相同，只是使用INTERNALTESSPOS代替POSITION语意，否则编译器会报位置语义的重用
            struct ControlPoint
            {
                float4 vertex : INTERNALTESSPOS;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float3 normal : NORMAL;
                float4 tangent  : TANGENT;
            };

            // 顶点着色器，此时只是将Attributes里的数据递交给曲面细分阶段
            ControlPoint BeforeTessVertProgram(Attributes v)
            {
                ControlPoint p;
        
                p.vertex = v.vertex;
                p.uv = v.uv;
                p.normal = v.normal;
                p.color = v.color;
                p.tangent = v.tangent;
        
                return p;
            }

            // 随着距相机的距离减少细分数
            float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
            {
                float3 worldPosition = TransformObjectToWorld(vertex.xyz);
                float dist = distance(worldPosition,  GetCameraPositionWS());
                float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
                return (f);
            }
            // 根据其距离相机的位置来设置细分因子
            TessellationFactors MyPatchConstantFunction(InputPatch<ControlPoint, 3> patch)
            {
                float minDist = _MinTessDistance;
                float maxDist = _MaxTessDistance;
            
                TessellationFactors f;
            
                float edge0 = CalcDistanceTessFactor(patch[0].vertex, minDist, maxDist, _Tess);
                float edge1 = CalcDistanceTessFactor(patch[1].vertex, minDist, maxDist, _Tess);
                float edge2 = CalcDistanceTessFactor(patch[2].vertex, minDist, maxDist, _Tess);
            
                // make sure there are no gaps between different tessellated distances, by averaging the edges out.
                f.edge[0] = (edge1 + edge2) / 2;
                f.edge[1] = (edge2 + edge0) / 2;
                f.edge[2] = (edge0 + edge1) / 2;
                f.inside = (edge0 + edge1 + edge2) / 3;
                return f;
            }

            //细分阶段
            [domain("tri")]//明确地告诉编译器正在处理三角形，其他选项：
            [outputcontrolpoints(3)]//明确地告诉编译器每个补丁输出三个控制点
            [outputtopology("triangle_cw")]//当GPU创建新三角形时，它需要知道我们是否要按顺时针或逆时针定义它们
            [partitioning("integer")]//告知GPU应该如何分割补丁，现在，仅使用整数模式
            [patchconstantfunc("MyPatchConstantFunction")]//GPU还必须知道应将补丁切成多少部分。每个补丁不同。必须提供一个补丁函数（Patch Constant Functions）
            [maxtessfactor(64.0f)] 
            ControlPoint HullProgram(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }
            
			Varyings AfterTessVertProgram (Attributes v)
			{
				float Amplitude[6] = {1.8, 0.8, 0.5, 0.3, 0.1, 0.08};
                float WaveLen[6] = {0.541, 0.6, 0.2, 0.3, 0.1, 0.3};
                float WindSpeed[6] = {0.305, 0.5, 0.34, 0.12, 0.64, 0.11};
                int WindDir[6] = {11, 90, 166, 300, 10, 180};
				Varyings o;
                float3 waveOffset = float3(0.0, 0.0, 0.0);
                // 计算水面波形
                for(int i = 0; i < 6; i++)
                {
                    Wave wave = GerstnerWave(v.vertex.xz, Amplitude[i], WaveLen[i], WindSpeed[i], WindDir[i]);
                    waveOffset += wave.wavePos;                    
                }
                
                // 置换顶点位置
                float HeightMap = SAMPLE_TEXTURE2D_LOD(_HeightMap,sampler_HeightMap,v.uv*_HeightMap_ST.xy+_HeightMap_ST.zw,0).r;
                v.vertex.xyz += v.normal * HeightMap * _StoneHeight;

                o.posWS = TransformObjectToWorld(v.vertex);

                // 计算遮罩
                
                float mask = smoothstep(o.posWS.y-_SmoothThresholdUp,o.posWS.y+_SmoothThresholdUp, waveOffset.y+_YThreshold+_YThresholdOffest);
                float mask2 = smoothstep(o.posWS.y-_SmoothThresholdDown,o.posWS.y+_SmoothThresholdDown, waveOffset.y+_YThreshold+(_YThresholdOffest -_EdgeOffest));
                float mask3 = smoothstep(o.posWS.y-_SmoothThresholdRim,o.posWS.y+_SmoothThresholdRim, waveOffset.y+_YThreshold+_RimThresholdOffest);
                o.mask = clamp(mask,0,1);
                o.mask2 = clamp(mask2,0,1);
                o.mask3 = clamp(mask3,0,1);

                // 截断顶点
                if(o.posWS.y < waveOffset.y + _YThreshold)
                {
                    o.posWS.y = waveOffset.y + _YThreshold;
                }
                
                // 增加岩浆厚度
                o.posWS.y += v.normal.y*mask2*_MagmaThickness;

                o.vertex = TransformWorldToHClip(o.posWS);
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.tDirWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.bDirWS = cross(o.nDirWS, o.tDirWS) * v.tangent.w * unity_WorldTransformParams.w;
				o.uv = v.uv;
                o.scrPos = ComputeScreenPos(o.vertex);
				o.color = v.color;
				o.waveOffset = waveOffset;
                o.shadowCoord = TransformWorldToShadowCoord(o.posWS);
                return o;
			}

            // 生成最终的顶点数据。
            [domain("tri")]// Hull着色器和Domain着色器都作用于相同的域，即三角形。我们通过domain属性再次发出信号
            Varyings DomainProgram(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
            {
                Attributes v;
                // 以相同的方式插值所有顶点数据
                #define DomainInterpolate(fieldName) v.fieldName = \
                        patch[0].fieldName * barycentricCoordinates.x + \
                        patch[1].fieldName * barycentricCoordinates.y + \
                        patch[2].fieldName * barycentricCoordinates.z;
    
                    // 对位置、颜色、UV、法线等进行插值
                    DomainInterpolate(vertex)
                    DomainInterpolate(uv)
                    DomainInterpolate(color)
                    DomainInterpolate(normal)
                    DomainInterpolate(tangent)
                    
                    // 该顶点将在此阶段之后发送到几何程序或插值器
                    return AfterTessVertProgram(v);
            }
            
            // 片段着色器
            float4 FragmentProgram(Varyings i) : SV_TARGET 
            {   
                // 准备向量
                Light light = GetMainLight(i.shadowCoord);//获取主光源数据
                float2 uv = i.uv;
                float shadow = MainLightRealtimeShadow(i.shadowCoord);
                float3 lDir = normalize(light.direction);
                float3 nDirWS = (0,0,0);
                if(i.posWS.y > i.waveOffset.y+_YThreshold+0.02)
                {
                    float3 nDirTS = normalize(UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,uv*_HeightMap_ST.xy+_HeightMap_ST.zw)));
                    float3x3 TBN = float3x3(i.tDirWS,i.bDirWS,i.nDirWS);
                    nDirWS = normalize(mul(nDirTS,TBN));
                }
                else
                {
                    nDirWS = i.nDirWS;
                }
                // 准备中间数据（点积结果）
                float nl = max(saturate(dot(nDirWS, lDir)), 0.000001);
                
                // 提取信息
                float3 magmaBaseColMask = SAMPLE_TEXTURE2D(_MagmaMap,smp_Point_Repeat,uv*_MagmaMap_ST.xy+_MagmaMap_ST.zw*_Time.y).rgb;
                float3 stoneBaseCol = SAMPLE_TEXTURE2D(_StoneMap,smp_Point_Repeat,uv*_StoneMap_ST.xy+_StoneMap_ST.zw).rgb;
                float3 magmaWarp = SAMPLE_TEXTURE2D(_MagmaWarpMap,sampler_MagmaWarpMap,uv*_MagmaWarpMap_ST.xy+_MagmaWarpMap_ST.zw*_Time.y).rgb;

                // 光照计算
                    // 岩石部分
                    float lambert = step(nl,_DiffRange);
                    float3 stoneCol = stoneBaseCol * lambert * _StoneCol.rgb;
                    float mask4 = smoothstep(i.posWS.y-_StoneSmoothThreshold,i.posWS.y+_StoneSmoothThreshold, i.waveOffset.y+_YThreshold+_StoneThresholdOffest);
                    stoneCol = lerp(stoneCol,_StoneEmissCol.rgb,mask4);
                    // 岩浆部分
                    float magmaEdgeMask = clamp(min(i.mask,(1-i.mask2)),0,1);
                    float2 uvBias = ((magmaWarp.rg - 0.5)*float2(_FlowDir.z,_FlowDir.w));
                    
                    float2 warpUv = uv + uvBias + float2(_FlowDir.x*_Time.x,_FlowDir.y*_Time.x);
                    float3 specCol = smoothstep(0.14,0.15,noise(warpUv*_SpecNoiseSize.x));
                    specCol -= smoothstep(0.185,0.29,noise(warpUv*_SpecNoiseSize.x));
                    specCol += smoothstep(0.185,0.19,noise(warpUv*_SpecNoiseSize.y))*_SpecNoiseSize.w;
                    specCol -= smoothstep(0.12,0.4,noise(warpUv*_SpecNoiseSize.y))*_SpecNoiseSize.w;
                    specCol = lerp(_SpecCol1.rgb,_SpecCol2.rgb,(1-specCol.x))*specCol.x;

                    float3 edgeCol = _EdgeCol.rgb;
                    float3 rimCol = _RimCol.rgb*(magmaWarp+0.3);
                    float3 baseCol = lerp(_MagmaCol1.rgb,_MagmaCol2.rgb,magmaBaseColMask.r);
                    float3 flowCol = lerp(rimCol.rgb,baseCol,i.mask3)+specCol;
                    float3 magmaCol = lerp(flowCol, edgeCol, magmaEdgeMask);

                // 混合
                float3 finalRGB = lerp(stoneCol,magmaCol,i.mask2);
                return float4(finalRGB,1.0);
                //return i.mask2;
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}