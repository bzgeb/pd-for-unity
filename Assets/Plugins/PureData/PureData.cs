using UnityEngine;
using System;
using System.Collections;

#if UNITY_ANDROID
using Platform = PureDataAndroid;
#elif UNITY_IPHONE
using Platform = PureDataIOS;
#elif UNITY_EDITOR || UNITY_STANDALONE
using Platform = PureDataCSharp;
#else
using Platform = PureDataDummy;
#endif

public class PureData {
	/* Public interface for use inside C# / JS code */
	public static int openFile( string filename )
	{
		return Platform.openFile( filename );
	}
	
	public static void closeFile( int handle )
	{
		Platform.closeFile( handle );
	}
	
	public static void initPd()
	{
		Platform.initPd();
	}
	
	public static void startAudio()
	{
		Platform.startAudio();
	}

	public static void pauseAudio()
	{
		Platform.pauseAudio();	
	}

	public static void stopAudio()
	{
		Platform.stopAudio();
	}
	
	public static void sendBangToReceiver(string receiver)
	{
		Platform.sendBangToReceiver( receiver );
	}
	
	public static void sendFloat(float aValue, string receiver)
	{
		Platform.sendFloat( aValue, receiver );
	}
	
	public static void subscribe(string symbol, string objectName, string methodName)
	{
		Platform.subscribe( symbol, objectName, methodName );
	}
	
	public static void sendSymbolToReceiver(string symbol, string receiver)
	{
		Platform.sendSymbolToReceiver( symbol, receiver );
	}
	
	public static void sendMessageToReceiver(string message, ArrayList arguments, string receiver)
	{
		Platform.sendMessageToReceiver( message, arguments, receiver );
	}
	
	public static void sendListToReceiver(ArrayList list, string receiver)
	{
		Platform.sendListToReceiver( list, receiver );
	}
	
//	public static void unsubscribe(string symbol)
//	{
//		if (Application.platform != RuntimePlatform.OSXEditor)
//			_unsubscribe(symbol.ToCharArray());
//	}
}
