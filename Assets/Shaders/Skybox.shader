Shader "Magma/Skybox"
{
    Properties
    {
        [Header(Texture)]
        _Stars              ("星空贴图", 2D) = "white" {}
        _GalaxyNoiseTex     ("银河噪声贴图", 2D) = "white" {}
        _GalaxyTex          ("银河贴图", 2D) = "white" {}
        _CloudNoise         ("云层噪声贴图", 2D) = "white" {}
        [Header(Galaxy and Stars)]
        [HDR]_GalaxyColor   ("银河颜色", color)=(0.02202741,0.1479551,0.3113208,1.0)
        [HDR]_GalaxyColor1  ("银河颜色1", color)=(0.0,0.1603774,0.02672958,1.0)
        _StarsSpeed         ("星星速度",float) = 0.01
        _StarsCutoff        ("星星裁剪范围",float) = 0.9
        _Exponent1          ("星空范围smoothstep参数1", float) = -0.8
        _Exponent2          ("星空范围smoothstep参数1", float) = -0.84
        [Header(Sun and Moon)]
        _SunRadius          ("太阳尺寸",float) = 0.12
        [HDR]_SunColor      ("太阳颜色日", color)=(1.735644,0.9867018,1.0,1.0)
        [HDR]_SunColor2     ("太阳颜色夜", color)=(1.735644,0.9867018,1.0,1.0)
        [HDR]_MoonColor     ("月亮颜色", color)=(4.237095,4.015257,2.772968,1.0)
        _MoonRadius         ("月亮尺寸",float) = 0.11
        _MoonOffset         ("月食范围",range(-0.5,0.5)) = -0.01
        [Header(SkyColor)]
        _DayBottomColor     ("白天底颜色", color)=(0.3287202,0.6532937,0.8396226,1.0)
        _DayTopColor        ("白天顶颜色", color)=(0.6745283,0.8685349,1.0,1.0)
        _NightBottomColor   ("夜晚底颜色", color)=(0.415064,0.4092204,0.7169812,1.0)
        _NightTopColor      ("夜晚顶颜色", color)=(0.07591571,0.0,0.509434,1.0)
        [Header(Cloud)]
        _CloudSpeed         ("云层速度",float) = 0.36
        _CloudCutoff        ("云层裁剪范围",float) = 1.84
        _DistortionSpeed    ("扰动速度", float) = 0.28
        _CloudNoiseScale    ("噪声图大小", float) = 0.33
        _DistortScale       ("扰动图大小", float) = 2.06
        _Fuzziness          ("云层平滑", float) = 0.75
        _FuzzinessSec       ("云层分层", float) = 1.61
        _CloudNight1        ("夜晚云颜色1", color)=(0.1105376,0.1848303,0.3396226,1.0)
        _CloudNight2        ("夜晚云颜色2", color)=(0.0,0.0,0.0,1.0)
        _CloudDay1          ("日间云颜色1", color)=(1.0,1.0,1.0,1.0)
        _CloudDay2          ("日间云颜色2", color)=(0.0,0.0,0.0,1.0)
        [Header(Horizon)]
        _HorizonIntensity   ("地平线强度", float) = 7.39
        _HorizonHeight      ("地平线高度", float) = 0.15
        [HDR]_HorizonColor  ("地平线颜色", color)=(1.74902,2.0,1.482353,1.0)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
        }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 4.6
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            uniform float4 _GalaxyColor;
            uniform float4 _GalaxyColor1;
            uniform float _SunRadius;
            uniform float4 _SunColor;
            uniform float4 _SunColor2;
            uniform float4 _MoonColor;
            uniform float _MoonRadius;
            uniform float _MoonOffset;
            uniform float4 _DayBottomColor;
            uniform float4 _DayTopColor;
            uniform float4 _NightBottomColor;
            uniform float4 _NightTopColor;
            uniform float _StarsSpeed;
            uniform float _CloudSpeed;
            uniform float _CloudCutoff;
            uniform float _StarsCutoff;
            uniform float _Exponent1;
            uniform float _Exponent2;
            uniform float _ExtinctionM;uniform float _ScatteringM;
            uniform float _DistortionSpeed;
            uniform float _CloudNoiseScale;
            uniform float _DistortScale;
            uniform float _Fuzziness;
            uniform float _FuzzinessSec;
            uniform float4 _CloudNight1;
            uniform float4 _CloudNight2;
            uniform float4 _CloudDay1;
            uniform float4 _CloudDay2;
            uniform float _HorizonIntensity;
            uniform float _HorizonHeight;
            uniform float4 _HorizonColor;
            half4 _StarColor;
            half _StarIntensity;
            half _StarSpeed;
            CBUFFER_END
            TEXTURE2D(_Stars);float4 _StarTex_ST;
            TEXTURE2D(_GalaxyNoiseTex);float4 _GalaxyNoiseTex_ST;
            TEXTURE2D(_GalaxyTex);float4 _GalaxyTex_ST;
            TEXTURE2D(_CloudNoise);
            SamplerState smp_Point_Repeat;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
                float3 texcoord : TEXCOORD1;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 posWS  : TEXCOORD1;
                float3 texcoord : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                o.posWS = TransformObjectToWorld(v.vertex);
                o.texcoord = v.texcoord;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                Light light = GetMainLight();//获取主光源数据
                //太阳               
                float3 sunUV = TransformObjectToWorld(i.uv.xyz);
                float sun = distance(i.uv.xyz, light.direction);
                float sunDisc = 1 - (sun / _SunRadius);
                sunDisc = saturate(sunDisc * 50);
                float3 fallSunColor = _SunColor2.rgb;
                float3 finalSunColor = lerp(fallSunColor,_SunColor.rgb,smoothstep(-0.1,1,light.direction.y)) * sunDisc;
                //月亮
                float moon = distance(i.uv.xyz, -light.direction); //日月方向相反
                float moonDisc = 1 - (moon / _MoonRadius);
                moonDisc = saturate(moonDisc * 50);

                float crescentMoon = distance(float3(i.uv.x + _MoonOffset, i.uv.yz), -light.direction);
                float crescentMoonDisc = 1 - (crescentMoon / _MoonRadius);
                crescentMoonDisc = saturate(crescentMoonDisc * 50);
                
                //float2 moonUV = sunUV.xy * _MoonTex_ST.xy * (1/_MoonRadius+0.001) + _MoonTex_ST.zw;
                //float4 moonTex = tex2D(_MoonTex, moonUV);
                moonDisc = saturate(moonDisc - crescentMoonDisc);
                float3 fallMoonColor = _MoonColor.rgb * 0.4;
                float3 finalMoonColor = lerp(fallMoonColor,_MoonColor.rgb,smoothstep(-0.1,0.1,-light.direction.y)) * moonDisc;

                float3 SunMoon = finalMoonColor + finalSunColor;
                float sunNightStep = saturate(smoothstep(-0.3,0.25,light.direction.y));
                //渐变天空
                float3 gradientDay = lerp(_DayBottomColor, _DayTopColor, saturate(i.uv.y));
                float3 gradientNight = lerp(_NightBottomColor, _NightTopColor, saturate(i.uv.y));
                float3 skyGradients = lerp(gradientNight, gradientDay,sunNightStep);

                //银河
                float4 galaxyNoiseTex = SAMPLE_TEXTURE2D(_GalaxyNoiseTex,smp_Point_Repeat,(i.uv.xz ) * _GalaxyNoiseTex_ST.xy + _GalaxyNoiseTex_ST.zw + float2(_Time.x * 0.2,_Time.x * 0.2));
                
                float4 galaxy = SAMPLE_TEXTURE2D(_GalaxyTex,smp_Point_Repeat,(i.uv.xz + (galaxyNoiseTex-0.5) * 0.3)*_GalaxyTex_ST.xy + _GalaxyTex_ST.zw);

                float4 galaxyColor =  (_GalaxyColor * (-galaxy.r+galaxy.g) + _GalaxyColor1 * galaxy.g) * smoothstep(-0.1,0.2,1-galaxy.g);

                galaxyNoiseTex = SAMPLE_TEXTURE2D(_GalaxyNoiseTex,smp_Point_Repeat,(i.uv.xz ) * _GalaxyNoiseTex_ST.xy + _GalaxyNoiseTex_ST.zw - float2(_Time.x * 0.2,_Time.x * 0.2));
                galaxy = SAMPLE_TEXTURE2D(_GalaxyTex,smp_Point_Repeat,(i.uv.xz + (galaxyNoiseTex-0.5)*0.3)*_GalaxyTex_ST.xy + _GalaxyTex_ST.zw);//采样两次noise

                galaxyColor +=  (_GalaxyColor * (-galaxy.r+galaxy.g) + _GalaxyColor1*galaxy.r) * smoothstep(0,0.3,1-galaxy.g);//两次计算color
                //计算星空遮罩
                float p = normalize(i.uv).y;
                float p1 = 1.0f - pow (min (1.0f, 1.0f - p), _Exponent1);
                float p3 = 1.0f - pow (min (1.0f, 1.0f + p), _Exponent2);
                float p2 = 1.0f - p1 - p3;
                float starMask = lerp((1 - smoothstep(-0.4,0.0,1-p2)),0,sunNightStep);
                galaxyColor *= 0.5 * starMask;
                
                //云层
                    //采样
                    //float2 skyuv = i.posWS.xz*0.1 / clamp(i.posWS.y, 0, 500)*i.posWS.y;
                    float2 skyuv = i.posWS.xz * 0.1 / (step(0,i.posWS.y) * i.posWS.y);
                    float3 cloud = SAMPLE_TEXTURE2D(_CloudNoise,smp_Point_Repeat,skyuv + float2(_CloudSpeed,_CloudSpeed) * _Time.x).xyz;
                    //cloud = step(_CloudCutoff, cloud);
                    //噪声
                    float distort = SAMPLE_TEXTURE2D(_CloudNoise,smp_Point_Repeat,(skyuv + (_Time.x * _DistortionSpeed)) * _DistortScale).r;
                    float noise = SAMPLE_TEXTURE2D(_CloudNoise,smp_Point_Repeat,((skyuv + distort ) - (_Time.x * _CloudSpeed)) * _CloudNoiseScale).r;
                    float finalNoise = saturate(noise) * 3 * saturate(i.posWS.y);
                    //平滑Cutoff
                    float cloudSec1 = saturate(smoothstep(_CloudCutoff * cloud.r, _CloudCutoff * cloud + _Fuzziness, finalNoise));
                    //颜色分层
                    float cloudSec2 = saturate(smoothstep(_CloudCutoff * cloud.r, _CloudCutoff * cloud + _FuzzinessSec, finalNoise));
                    
                    //昼夜颜色变化
                    float3 CloudGradients1 = lerp(_CloudNight1, _CloudDay1,sunNightStep).rgb;
                    float3 CloudGradients2 = lerp(_CloudNight2, _CloudDay2,sunNightStep).rgb;
                    float3 cloudColin = lerp(0,CloudGradients1,cloudSec2);
                    float3 cloudColout = lerp(0,CloudGradients2,cloudSec1 - cloudSec2);
                    cloud = cloudColin + cloudColout;
                //星空
                float3 stars = SAMPLE_TEXTURE2D(_Stars,smp_Point_Repeat,i.uv.xz * 0.6 + float2(_StarsSpeed,_StarsSpeed) * _Time.x).rgb;
                float3 starNoiseTex = SAMPLE_TEXTURE2D(_GalaxyNoiseTex,smp_Point_Repeat,i.uv.xz + float2(_StarsSpeed,_StarsSpeed) * _Time.y).rgb;
                stars = step(_StarsCutoff, stars);
                float starPos = smoothstep(0.21,0.31,stars.r) * starMask;
                float starBright = smoothstep(0.4,0.5,starNoiseTex.r);
                
                float starColor = starPos * starBright;
                starColor = starColor * galaxy.r * 0.2 + starColor * (1-galaxy.r) * 3;
                float3 StarColor = starColor * (1 - cloud);

                //地平线/模拟大气散射
                float3 horizon = abs((i.uv.y * _HorizonIntensity) - _HorizonHeight);
                float Newp = smoothstep(-0.2,0.2,light.direction.y);
                horizon = saturate((1 - horizon)) * (lerp(_HorizonColor.rgb,float3(0.0,0.0,0.0),Newp) * Newp);

                //混合
                float3 finalColor = SunMoon + skyGradients + (StarColor + galaxyColor.rgb)  + horizon + cloud;//+finalSunInfColor
                finalColor += skyGradients * 0.2;

                return float4(finalColor,1.0);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}
