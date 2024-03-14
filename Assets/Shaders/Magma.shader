Shader "Magma/Magma"
{
    Properties
    {
        [Header(Magma)]
        [HDR]_MagmaCol1             ("岩浆颜色1", Color) = (1,1,1,1)
        _MagmaCol2                  ("岩浆颜色2", Color) = (1,1,1,1)
        _EdgeOffest                 ("岩浆边缘阴影范围偏移", Range(-0.1,0.1)) = 0
        _EdgeCol                    ("岩浆边缘阴影颜色", Color) = (1,1,1,1)
        _SmoothThreshold            ("岩浆边缘阴影平滑阈值", Range(0,0.1)) = 0
        [HDR]_RimCol            ("岩浆边缘光颜色", Color) = (1,1,1,1)
        _SmoothThresholdRim     ("岩浆边缘光平滑阈值", Range(0,0.5)) = 0
        _RimThresholdOffest     ("边缘光范围阈值", Range(-1,1)) = -0.2
        _SpecNoiseSize          ("高光噪声大小XY  强度W", Vector) = (10,0,0,0)
        [HDR]_SpecCol1          ("岩浆高光颜色1", Color) = (1,1,1,1)
        _SpecCol2               ("岩浆高光颜色2", Color) = (1,1,1,1)
        _FlowDir                ("流动方向XY", Vector) = (2,2,0,0)
        [Toggle] _T1            ("实时计算噪声纹理?", Float) = 0

        [Header(Stone)]
        _StoneCol1              ("岩石颜色暗面", Color) = (1,1,1,1)
        _StoneCol2              ("岩石颜色亮面", Color) = (1,1,1,1)
        _DiffRange              ("明暗交界线阈值", Float) = 1
        _StoneHeight            ("岩石高度偏移", Float) = 1
        _YThreshold             ("岩浆平面高度偏移", Float) = 1
        _StoneThresholdOffest   ("岩石自发光范围阈值", Range(-1,1)) = 0.0
        _StoneSmoothThreshold   ("岩石自发光范围平滑度", Range(-1,1)) = 0.0
        [HDR]_StoneEmissCol     ("岩石自发光颜色", Color) = (1,1,1,1)

        [Header(Shadow)]
        _ShadowCol          ("接受投影颜色", Color) = (0,0,0,0)
        [Toggle] _T2        ("接受阴影?", Float) = 0

        [Header(Texture)]
        _HeightMap          ("置换贴图",2D)    = "white" {}
        _StoneMap           ("岩石颜色贴图",2D)    = "white" {}
        _NormalMap          ("法线贴图",2D)    = "bump" {}
        _AOMap              ("环境光遮蔽贴图",2D)    = "white" {}
        _MagmaMap           ("岩浆底层噪声贴图",2D)    = "white" {}
        _MagmaWarpMap       ("岩浆高光扰动贴图",2D)    = "white" {}
        _MagmaNoiseMap      ("岩浆高光噪声贴图",2D)    = "white" {}
        
        [Header(Tessellation)]
        _Tess               ("细分程度", Range(1,32)) = 20
        _MaxTessDistance    ("细分最大距离", Range(1,100)) = 20
        _MinTessDistance    ("细分最小距离", Range(1,50)) = 1
        _DisStrength        ("视锥体裁剪", Range(0,2)) = 1
        _MagmaThickness     ("岩浆厚度", Range(0,1)) = 0

        [Header(Wave)]
        _Steepness          ("重力",Range(0,5)) = 0.8
        _Amplitude          ("振幅",Range(0,0.2)) = 0.06
        _WaveLength         ("波长",Range(0,10)) = 1
        _WindSpeed          ("风速",Range(0,1)) = 1
        _WindDir            ("风向",Range(0,360)) = 0
        
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
            Name "MainPass"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
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
            #pragma shader_feature _T1_ON
            #pragma shader_feature _T2_ON
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GeometricTools.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Tessellation.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Assets/Shaders/Common.hlsl"
            #include "Assets/Shaders/DynamicTessellationFactors.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float _Tess;
            float _MaxTessDistance;
            float _MinTessDistance;
            float _DisStrength;
            float _MagmaThickness;
            
            float4 _StoneCol1;
            float4 _StoneCol2;
            float4 _MagmaCol1;
            float4 _MagmaCol2;
            float _EdgeOffest;
            float4 _EdgeCol;
            float4 _RimCol;
            float _SmoothThreshold;
            float _SmoothThresholdRim;
            float _RimThresholdOffest;
            float4 _SpecCol1;
            float4 _SpecCol2;
            float4 _FlowDir;
            float _StoneHeight;
            float _YThreshold;
            float _StoneThresholdOffest;
            float _StoneSmoothThreshold;
            float4 _StoneEmissCol;
            float4 _ShadowCol;
            float _DiffRange;
            float4 _MainTexture_Texelsize;
            
            CBUFFER_END
            TEXTURE2D(_HeightMap);
            float4 _HeightMap_ST;
            SAMPLER(sampler_HeightMap);
            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_AOMap);
            SAMPLER(sampler_AOMap);
            TEXTURE2D(_StoneMap);
            SAMPLER(sampler_StoneMap);
            TEXTURE2D(_MagmaMap);
            SAMPLER(sampler_MagmaMap);
            float4 _MagmaMap_ST;
            TEXTURE2D(_MagmaWarpMap);
            SAMPLER(sampler_MagmaWarpMap);
            float4 _MagmaWarpMap_ST;

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
                float3 posWS : TEXCOORD1;
                float4 scrPos :TEXCOORD2;  
                float3 tDirWS : TEXCOORD3;
                float3 bDirWS : TEXCOORD4;
                float3 waveOffset : TEXCOORD5;
                float4 shadowCoord : TEXCOORD6;
                float mask : TEXCOORD7;
                float mask2 : TEXCOORD8;
                float mask3 : TEXCOORD9;
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
            
            // 设置细分因子
            TessellationFactors MyPatchConstantFunction(InputPatch<ControlPoint, 3> patch)
            {
                float minDist = _MinTessDistance;
                float maxDist = _MaxTessDistance;
            
                TessellationFactors f;
                
                float edge0 = CalcDistanceTessFactor(patch[0].vertex, minDist, maxDist, _Tess);
                float edge1 = CalcDistanceTessFactor(patch[1].vertex, minDist, maxDist, _Tess);
                float edge2 = CalcDistanceTessFactor(patch[2].vertex, minDist, maxDist, _Tess);

                float3 p0 = mul(unity_ObjectToWorld, patch[0].vertex).xyz;
                float3 p1 = mul(unity_ObjectToWorld, patch[1].vertex).xyz;
                float3 p2 = mul(unity_ObjectToWorld, patch[2].vertex).xyz;
                float bias = -0.5 * _DisStrength;
                if (TriangleIsCulled(p0, p1, p2, bias)) 
                {
                    f.edge[0] = f.edge[1] = f.edge[2] = f.inside = 0;
                }
                else 
                {
                // make sure there are no gaps between different tessellated distances, by averaging the edges out.
                f.edge[0] = (edge1 + edge2) / 2;
                f.edge[1] = (edge2 + edge0) / 2;
                f.edge[2] = (edge0 + edge1) / 2;
                f.inside = (edge0 + edge1 + edge2) / 3;
                }
                return f;
            }

            //细分阶段
            [domain("tri")]//明确地告诉编译器正在处理三角形，其他选项：
            [outputcontrolpoints(3)]//明确地告诉编译器每个补丁输出三个控制点
            [outputtopology("triangle_cw")]//当GPU创建新三角形时，它需要知道我们是否要按顺时针或逆时针定义它们
            [partitioning("fractional_even")]//告知GPU应该如何分割补丁
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
                
                // 置换顶点位置
                float HeightMap = SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, v.uv * _HeightMap_ST.xy + _HeightMap_ST.zw, 0).r;
                v.vertex.xyz += v.normal * HeightMap * _StoneHeight;

                o.posWS = TransformObjectToWorld(v.vertex.xyz);

                // 计算水面波形
                for(int i = 0; i < 6; i++)
                {
                    Wave wave = GerstnerWave(o.posWS.xz, Amplitude[i], WaveLen[i], WindSpeed[i], WindDir[i]);
                    waveOffset += wave.wavePos;                    
                }
                
                // 计算遮罩
                
                float mask = smoothstep(o.posWS.y - 0.1, o.posWS.y + 0.1, waveOffset.y + _YThreshold);
                float mask2 = smoothstep(o.posWS.y - _SmoothThreshold, o.posWS.y + _SmoothThreshold, waveOffset.y + _YThreshold - _EdgeOffest);
                float mask3 = smoothstep(o.posWS.y - _SmoothThresholdRim, o.posWS.y + _SmoothThresholdRim, waveOffset.y + _YThreshold + _RimThresholdOffest);
                o.mask = clamp(mask, 0, 1);
                o.mask2 = clamp(mask2, 0, 1);
                o.mask3 = clamp(mask3, 0, 1);

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
                #ifdef _T2_ON
                o.shadowCoord = TransformWorldToShadowCoord(o.posWS);
                #endif
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
                #ifdef _T2_ON
                    Light light = GetMainLight(i.shadowCoord);          // 获取主光源数据
                    float shadow = MainLightRealtimeShadow(i.shadowCoord);
                #else
                    Light light = GetMainLight();      // 获取主光源数据
                #endif
                float2 uv = i.uv;
                float3 lDir = normalize(light.direction);
                float3 nDirWS = (0,0,0);
                float3 nDirTS = normalize(UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv * _HeightMap_ST.xy + _HeightMap_ST.zw)));
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                nDirWS = normalize(mul(nDirTS, TBN));
                // 准备中间数据（点积结果）
                float nl = saturate(dot(nDirWS, lDir));
                
                // 提取信息
                float2 uvWS = i.posWS.xz;
                float3 magmaBaseColMask = SAMPLE_TEXTURE2D(_MagmaMap, sampler_MagmaMap, uvWS * _MagmaMap_ST.xy + _MagmaMap_ST.zw * _Time.y).rgb;
                float3 stoneBaseCol = SAMPLE_TEXTURE2D(_StoneMap, sampler_StoneMap, uv * _HeightMap_ST.xy + _HeightMap_ST.zw).rgb;
                float3 magmaWarp = SAMPLE_TEXTURE2D(_MagmaWarpMap, sampler_MagmaWarpMap, uvWS * _MagmaWarpMap_ST.xy + _MagmaWarpMap_ST.zw * _Time.y).rgb;
                float aoMap = SAMPLE_TEXTURE2D(_AOMap,sampler_AOMap, uv * _HeightMap_ST.xy + _HeightMap_ST.zw).r;

                // 光照计算
                    // 岩石部分
                    float lambert = smoothstep(_DiffRange - 0.02, _DiffRange + 0.02, nl);
                    float3 stoneCol = lerp(stoneBaseCol * _StoneCol1.rgb,stoneBaseCol * _StoneCol2.rgb, lambert);
                    float mask4 = smoothstep(i.posWS.y - _StoneSmoothThreshold, i.posWS.y + _StoneSmoothThreshold, i.waveOffset.y + _YThreshold + _StoneThresholdOffest);
                    stoneCol = lerp(stoneCol, _StoneEmissCol.rgb,mask4) * aoMap;
                    // 岩浆部分
                    float magmaEdgeMask = clamp(min(i.mask, (1 - i.mask2)), 0, 1);
                    float2 uvBias = ((magmaWarp.rg - 0.5) * float2(_FlowDir.z, _FlowDir.w));
                    
                    float2 warpUv = uvWS + uvBias + float2(_FlowDir.x * _Time.x, _FlowDir.y * _Time.x);
                    float specNoise = 0;
                    #ifdef _T1_ON
                        specNoise = RealTimePerlinNoises(warpUv);
                    #else
                        specNoise = SamplePerlinNoises(warpUv);
                    #endif
                    float3 specCol = lerp(_SpecCol1.rgb, _SpecCol2.rgb, (1 - specNoise)) * specNoise;
                    float3 edgeCol = _EdgeCol.rgb;
                    float3 rimCol = _RimCol.rgb*(magmaWarp + 0.3);
                    float3 baseCol = lerp(_MagmaCol1.rgb, _MagmaCol2.rgb, magmaBaseColMask.r);
                    float3 flowCol = lerp(rimCol.rgb, baseCol, i.mask3) + specCol;
                    float3 magmaCol = lerp(flowCol, edgeCol, magmaEdgeMask);

                // 混合
                float3 finalRGB = lerp(stoneCol, magmaCol, i.mask2);
                #ifdef _T2_ON
                    finalRGB = lerp(finalRGB * _ShadowCol.rgb, finalRGB, shadow);
                #endif
                return float4(finalRGB, 1.0);
                //return shadow;
            }

            ENDHLSL
        }
        
        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            // Universal Pipeline keywords
            #pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}