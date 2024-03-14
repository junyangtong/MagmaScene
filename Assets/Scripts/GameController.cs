using UnityEditor;
using UnityEngine;

public class GameController : MonoBehaviour
{
    public void ExitGame()
    {

    #if UNITY_EDITOR
            EditorApplication.isPlaying = false;
    #else
            Application.Quit();
    #endif
    }
}
