using UnityEngine;
using System.Collections;

public class PDGui : MonoBehaviour {
    void OnGUI() {
        GUILayout.BeginArea( new Rect(20, 20, 100, 1000) );
        GUILayout.BeginVertical();
        if ( GUILayout.Button( "Open File" ) ) {
            PureData.openFile("BasicSynth.pd");
        }
        GUILayout.Space(15);
        if ( GUILayout.Button( "Close File" ) ) {
            PureData.closeFile("BasicSynth.pd");
        }
        GUILayout.EndVertical();
        GUILayout.EndArea();
    }
}
