using UnityEngine;
using System.Collections;

public class PureDataAndroid {
    static AndroidJavaObject PdWrapper;

    public static void openFile( string filename ) {
        PdWrapper.Call( "openFile", filename );
    }

    public static void closeFile( string filename ) {
        PdWrapper.Call( "closeFile", filename );
    }

    public static void initPd() {
        AndroidJavaClass jc = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
        AndroidJavaObject jo = jc.GetStatic<AndroidJavaObject>("currentActivity"); 

        //Initialize the Wrapper object with the current activity
        PdWrapper = new AndroidJavaObject( "com.bronsonzgeb.android.unity.Wrapper", jo );
        PdWrapper.Call( "initPd" );
    }

    public static void startAudio() {
        PdWrapper.Call( "startAudio" );
    }

    public static void pauseAudio() {
        PdWrapper.Call( "pauseAudio" );
    }

    public static void stopAudio() {
        PdWrapper.Call( "stopAudio" );
    }

    public static void sendBangToReceiver( string receiver ) {
        PdWrapper.Call( "sendBang", receiver );
    }

    public static void sendFloat( float aValue, string receiver ) {
        PdWrapper.Call( "sendFloat", aValue, receiver );
    }

    public static void subscribe( string symbol, string objectName, string methodName ) {

    }

    public static void sendSymbolToReceiver( string symbol, string receiver ) {
        PdWrapper.Call( "sendSymbol", symbol, receiver );
    }

    public static void sendMessageToReceiver( string message, ArrayList arguments, string receiver ) {
    }

    public static void sendListToReceiver( ArrayList list, string receiver ) {
    }
}