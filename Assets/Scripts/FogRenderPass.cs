using UnityEngine; 
using UnityEngine.Rendering; 
using UnityEngine.Rendering.Universal; 
 
public class FogRenderPass : ScriptableRenderPass 
{ 
    // 用于FrameDebugger或其他Profiler中显示的名字
    private const string m_ProfilerTag = "MyFogRenderPass";

    private RenderTargetIdentifier m_Source;
    private RenderTargetHandle m_Destination;//申请临时rt所必须的

    public FogRenderPass(RenderPassEvent evt) 
    { 
        // 设置Pass的执行顺序 
        renderPassEvent = evt; 
    } 

    public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination)
    {
        m_Source = source;
        m_Destination = destination;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        // 装配 给拷贝目标分配实际显存
        var descriptor = cameraTextureDescriptor;
        // 该结构包含创建 RenderTexture 所需的所有信息depthBufferBits为设置纹理深度精度
        descriptor.depthBufferBits = 0;
        // GetTemporaryRT获取当前相机图像
        cmd.GetTemporaryRT(m_Destination.id, descriptor, FilterMode.Point);
    }

    // 重写Execute 在此执行渲染逻辑
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) 
    { 
        // 执行拷贝命令
        // 创建一个新的CommandBuffer
        CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
        cmd.Blit(m_Source, m_Destination.Identifier()); //.Identifier():实例化rt
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    } 
    
    // 释放显存
    public override void FrameCleanup(CommandBuffer cmd)
    {
        if (m_Destination != RenderTargetHandle.CameraTarget)
        {
            // 释放拷贝目标
            cmd.ReleaseTemporaryRT(m_Destination.id);
            m_Destination = RenderTargetHandle.CameraTarget;
        }
    }
} 