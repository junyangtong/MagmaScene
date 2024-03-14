using UnityEngine;

public class CameraController : MonoBehaviour
{
    Camera wanderCamera;
    bool isWanderCam = false;
    int CameraIndex = 1;
    /// <summary>
    /// 玩家输入控制
    /// </summary>
    Vector2 userInput = Vector2.zero;
    Vector2 mouseDelta = Vector2.zero;
    /// <summary>
    /// 鼠标移动灵敏度
    /// </summary>
    float sensitivity = 2;
    /// <summary>
    /// 移动中平滑
    /// </summary>
    float smoothing = 1.5f;
    Vector2 velocity, frameVelocity;
    bool isRunning = false;
    float upSpeed = 0.2f;
    float upDistance;
    private void Start()
    {
        wanderCamera = GetComponent<Camera>();
    }
    private void Update()
    {
        GetUserInput();
        WanderCameraCtrl();
        //使用QE控制相机的上下
        {
            if (Input.GetKey(KeyCode.Q))
            {
                upDistance -= upSpeed * Time.deltaTime;
                transform.Translate(transform.up * upDistance, Space.World);
            }
            else if(Input.GetKeyUp(KeyCode.Q))
            {
                upDistance = 0;
            }
            if (Input.GetKey(KeyCode.E))
            {
                upDistance += upSpeed * Time.deltaTime;
                transform.Translate(transform.up * upDistance, Space.World);
            }
            else if(Input.GetKeyUp(KeyCode.E))
            {
                upDistance = 0;
            }
        }
    }
    void GetUserInput()
    {
        userInput.x = Input.GetAxis("Horizontal");
        userInput.y = Input.GetAxis("Vertical");
        mouseDelta.x = Input.GetAxisRaw("Mouse X");
        mouseDelta.y = Input.GetAxisRaw("Mouse Y");
    }
    public float wanderCameraMoveSpeed = 10;
    [HideInInspector]
    public float wanderCameraRunSpeed=20;
    void WanderCameraCtrl()
    {
        float moveSpeed= isRunning ? wanderCameraRunSpeed : wanderCameraMoveSpeed;
        userInput = userInput * Time.deltaTime * moveSpeed;
        wanderCamera.transform.Translate(userInput.x, 0, userInput.y);
        Vector2 rawFrameVelocity = Vector2.Scale(mouseDelta, Vector2.one * sensitivity);
        frameVelocity = Vector2.Lerp(frameVelocity, rawFrameVelocity, 1 / smoothing);
        velocity += frameVelocity;
        wanderCamera.transform.localRotation = Quaternion.Euler(-velocity.y, velocity.x, 0);
    }
}
