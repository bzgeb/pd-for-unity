using UnityEngine;
using System.Collections;

public class PureDataDummy {
    public static void openFile( string filename ) {
        Debug.Log("openFile Not Implemented");
    }

    public static void closeFile( string filename ) {
        Debug.Log("closeFile Not Implemented");
    }

    public static void initPd() {
        Debug.Log("initPd Not Implemented");
    }

    public static void startAudio() {
        Debug.Log("startAudio Not Implemented");
    }

    public static void pauseAudio() {
        Debug.Log("pauseAudio Not Implemented");
    }

    public static void stopAudio() {
        Debug.Log("stopAudio Not Implemented");
    }

    public static void sendBangToReceiver( string receiver ) {
        Debug.Log("sendBangToReceiver Not Implemented");
    }

    public static void sendFloat( float aValue, string receiver ) {
        Debug.Log("sendFloat Not Implemented");
    }

    public static void subscribe( string symbol, string objectName, string methodName ) {
        Debug.Log("subscribe Not Implemented");
    }

    public static void sendSymbolToReceiver( string symbol, string receiver ) {
        Debug.Log("sendSymbolToReceiver Not Implemented");
    }

    public static void sendMessageToReceiver( string message, ArrayList arguments, string receiver ) {
        Debug.Log("sendMessageToReceiver Not Implemented");
    }

    public static void sendListToReceiver( ArrayList list, string receiver ) {
        Debug.Log("sendListToReceiver Not Implemented");
    }   
}