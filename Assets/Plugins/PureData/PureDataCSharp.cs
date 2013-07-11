#if UNITY_EDITOR || UNITY_STANDALONE
using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.IO;

public class PureDataCSharp {
    private static Dictionary<int, IntPtr> OpenPatches = new Dictionary<int, IntPtr>();

    [DllImport("libpd", EntryPoint="libpd_openfile")]
    private static extern IntPtr openfile([In] [MarshalAs(UnmanagedType.LPStr)] string basename, [In] [MarshalAs(UnmanagedType.LPStr)] string dirname);

    [DllImport("libpd", EntryPoint="libpd_closefile")]
    private static extern void closefile(IntPtr p);

    [DllImport("libpd", EntryPoint="libpd_init")]
    private static extern void libpd_init();

    [DllImport("libpd", EntryPoint="libpd_init_audio")]
    private static extern int libpd_init_audio(int nInputs, int nOutputs, int sampleRate);

    [DllImport("libpd", EntryPoint="libpd_bang")]
    private static extern int send_bang([In] [MarshalAs(UnmanagedType.LPStr)] string recv);

    [DllImport("libpd", EntryPoint="libpd_float")]
    private static extern int send_float([In] [MarshalAs(UnmanagedType.LPStr)] string recv, float x);

    [DllImport("libpd", EntryPoint="libpd_symbol")]
    private static extern int send_symbol([In] [MarshalAs(UnmanagedType.LPStr)] string recv, [In] [MarshalAs(UnmanagedType.LPStr)] string sym);

    [DllImport("libpd", EntryPoint="libpd_getdollarzero")]
    private static extern int getdollarzero(IntPtr p) ;

    [MethodImpl(MethodImplOptions.Synchronized)]
    public static int openFile( string filepath ) {
        filepath = Application.dataPath + "/Patches/" + filepath; 
        Debug.Log("?");
        if( !File.Exists(filepath) ) {
                throw new FileNotFoundException( filepath );
        }

        var ptr = openfile( Path.GetFileName(filepath), Path.GetDirectoryName(filepath) );

        if( ptr == IntPtr.Zero ) {
            throw new IOException( "unable to open patch " + filepath );
        }

        var handle = getdollarzero(ptr);

        OpenPatches[handle] = ptr;

        Debug.Log("Opening");

        return handle;
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public static void closeFile( int handle ) {
        if( !OpenPatches.ContainsKey( handle ) ) {
            return;  
        }

        var ptr = OpenPatches[handle];
        closefile( ptr );

        Debug.Log("Closed");

        OpenPatches.Remove( handle );
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public static void initPd() {
        libpd_init();
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public static void startAudio() {
        if ( libpd_init_audio(2, 2, 48000) != 0 ) {
            Debug.Log("Failed to init Pd");
        }
    }

    public static void pauseAudio() {

    }

    public static void stopAudio() {

    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public static void sendBangToReceiver( string receiver ) {
        send_bang( receiver );
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public static void sendFloat( float aValue, string receiver ) {
        send_float( receiver, aValue );
    }

    public static void subscribe( string symbol, string objectName, string methodName ) {
    }

    [MethodImpl(MethodImplOptions.Synchronized)]
    public static void sendSymbolToReceiver( string symbol, string receiver ) {
        send_symbol( receiver, symbol );
    }

    public static void sendMessageToReceiver( string message, ArrayList arguments, string receiver ) {
    }

    public static void sendListToReceiver( ArrayList list, string receiver ) {
    }
}
#endif
