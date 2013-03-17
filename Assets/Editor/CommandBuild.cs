using UnityEngine;
using UnityEditor;

public class CommandBuild {

    public static void BuildAndroid() {
        string[] levels = {"Assets/Test01.unity"};
        BuildPipeline.BuildPlayer(levels, "Android.apk", BuildTarget.Android, BuildOptions.None);
    }
}