Shader "Magma/Stone"
{
    Properties 
    {
        _DiffStep       ("明暗交界线阈值",Range(0,1)) = 0.5
        _BaseColor1     ("暗面颜色", Color) = (1,1,1,1)
        _BaseColor2     ("亮面颜色", Color) = (0,0,0,0)
        _EmissCol         ("自发光颜色上", Color) = (1,1,1,1)
        [HDR]_ContactEmissCol("自发光颜色下", Color) = (1,1,1,1)
        _EmissVector     ("自发光方向XYZ 高度W",Vector) = (1,1,1,1)
        _ContactColHeight("接触颜色高度",float) = 0.5
        _ShadowCol         ("阴影颜色", Color) = (1,1,1,1)
        [Header(Texture)]
        _MainMap        ("颜色贴图", 2D) = "white" {}
        _AOMap        ("环境光遮蔽",2D)="white"{}
        _NormalMap        ("法线",2D)="bump"{}

   }
   SubShader {
       Tags
       {
           "RenderPipeline"="UniversalPipeline"
           "RenderType" = "Opaque"
           "Queue"="Geometry"
       }
       Pass {
           Name "Stone"
           Tags 
           {
               "LightMode" = "UniversalForward"
           }

           HLSLPROGRAM
           
           #pragma vertex vert
           #pragma fragment frag
           
           #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
           #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
           #pragma multi_compile _ Anti_Aliasing_ON

           #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
           #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
           #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

           //获取参数
           CBUFFER_START(UnityPerMaterial)
           float _DiffStep;
           float4 _BaseColor1;
           float4 _BaseColor2;
           float4 _ShadowCol;
           float _ContactColHeight;
           float4 _ContactEmissCol;
           float4 _EmissCol;
           float4 _EmissVector;
           CBUFFER_END

           TEXTURE2D(_MainMap);
           SAMPLER(sampler_MainMap);
           float4 _MainMap_ST;
           TEXTURE2D(_WarpTex);
           TEXTURE2D(_NormalMap);
           SAMPLER(sampler_NormalMap);
           float4 _NormalMap_ST;
           #define textureSampler1 SamplerState_Point_Repeat
           SAMPLER(textureSampler1);

           //输入结构
           struct VertexInput 
           {
               float4 vertex : POSITION;
               float2 uv : TEXCOORD0;
               float3 normal : NORMAL;
               float4 tangent  : TANGENT;
           };
           //输出结构
           struct VertexOutput 
           {
               float4 pos : SV_POSITION;
               float2 uv : TEXCOORD0;
               float4 posWS :TEXCOOND1;
               float3 tDirWS : TEXCOORD2;
               float3 bDirWS : TEXCOORD3; 
               float3 nDirWS : NORMAL_WS;  
               float4 shadowCoord : TEXCOORD4;
           };
           //输出结构>>>顶点Shader>>>输出结构
           VertexOutput vert (VertexInput v) 
           {
                VertexOutput o = (VertexOutput)0;
                o.pos = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv,_MainMap);
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                o.nDirWS = TransformObjectToWorldNormal(v.normal);
                o.tDirWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.bDirWS = cross(o.nDirWS, o.tDirWS) * v.tangent.w * unity_WorldTransformParams.w;
                o.shadowCoord = TransformWorldToShadowCoord(o.posWS);
                return o;
           }
           //输出结构>>>像素
           float4 frag(VertexOutput i) : COLOR {
               //向量准备
               Light light = GetMainLight(i.shadowCoord);// 获取主光源数据
               float shadow = MainLightRealtimeShadow(i.shadowCoord);
               float3 nDirTS = normalize(UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap,i.uv*_NormalMap_ST.xy+_NormalMap_ST.zw)));
               float3x3 TBN = float3x3(i.tDirWS,i.bDirWS,i.nDirWS);        // 计算TBN矩阵                        
               float3 nDirWS = normalize(mul(nDirTS,TBN));
               float3 lDir = normalize(light.direction);
               float3 vDirWS = normalize (_WorldSpaceCameraPos.xyz - i.posWS);                     //视线方向                   
               float3 hDir = normalize (vDirWS+lDir);
               // 准备中间数据
               float nl = saturate(dot(nDirWS, lDir));
               float emissMask = saturate(dot(nDirWS, _EmissVector));
               emissMask *= smoothstep(i.posWS.y-13,i.posWS.y+13,_EmissVector.w);
               float contactColMask = emissMask*smoothstep(i.posWS.y-0.5,i.posWS.y+0.5,_ContactColHeight);
               //提取信息
               float3 mainTex = SAMPLE_TEXTURE2D(_MainMap,sampler_MainMap,i.uv).rgb;
               //光照计算
                    //漫反射颜色
                    float diffMask = smoothstep(_DiffStep-0.05,_DiffStep+0.05,nl);
                    float3 diffCol =  lerp(mainTex * _BaseColor1.rgb,mainTex * _BaseColor2.rgb,diffMask);
                    
                    //自发光颜色
                    float3 emiss = _EmissCol.rgb * emissMask;
                    float3 contactCol = _ContactEmissCol.rgb * contactColMask;
                    emiss = emiss + contactCol;
               //finalRGB
               float3 finalRGB = lerp(_ShadowCol.rgb*diffCol,diffCol,shadow)+emiss;
               return float4(finalRGB,1.0);
           }
           ENDHLSL
       }
       
   }
  }