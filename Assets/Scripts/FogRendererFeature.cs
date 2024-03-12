using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class FogRendererFeature : ScriptableRendererFeature 
{   // 故障效果shader
    //public Shader glitchImageBlockShader;

    // 声明屏幕缓冲rt
    private RenderTargetHandle m_CameraColorAttachment;
    
    // 拷贝目标rt
    private RenderTargetHandle m_CameraTransparentColorAttachment;
    
    // 屏幕拷贝Pass
    private FogRenderPass m_FogRenderPass;

    // 故障效果pass
    //private GlitchImageBlockPass m_GlitchImageBlockPass;

    // 故障效果材质球
    //private Material m_glitchmaterial;

    //Initializes this feature's resources.
    public override void Create() 
    { 
        // 初始化Pass
        m_FogRenderPass = new FogRenderPass(RenderPassEvent.AfterRenderingTransparents);
        //m_GlitchImageBlockPass = new GlitchImageBlockPass(RenderPassEvent.AfterRenderingTransparents);

        // 传入到显存中的rt
        m_CameraColorAttachment.Init("_CameraColorTexture");
        m_CameraTransparentColorAttachment.Init("_CameraTransparentColorTexture");

        // 初始化材质球
        //m_glitchmaterial = new Material(glitchImageBlockShader);
    } 

    //Injects one or multiple ScriptableRenderPass in the renderer.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) 
    { 
        // 添加FogPass
        m_FogRenderPass.Setup(m_CameraColorAttachment.Identifier(), m_CameraTransparentColorAttachment);
        renderer.EnqueuePass(m_FogRenderPass);   // 将pass加入到待执行队列中

        // 添加故障效果pass
        //m_GlitchImageBlockPass.Setup(m_CameraTransparentColorAttachment.Identifier(), m_CameraColorAttachment.Identifier(), m_glitchmaterial);
        //renderer.EnqueuePass(m_GlitchImageBlockPass);
    } 
} 
 