#if !UNITY_ANDROID && !UNITY_IPHONE
using UnityEngine;
using System.Collections;

public class PureDataCSharp {
    private static Dictionary<int, IntPtr> OpenPatches = new Dictionary<int, IntPtr>();

    [DllImport("libpdcsharp", EntryPoint="libpd_openfile")]
    private static extern  IntPtr openfile([In] [MarshalAs(UnmanagedType.LPStr)] string basename, [In] [MarshalAs(UnmanagedType.LPStr)] string dirname);

    [DllImport("libpdcsharp", EntryPoint="libpd_closefile")]
    private static extern  void closefile(IntPtr p);

    [DllImport("libpdcsharp", EntryPoint="libpd_safe_init")]
    private static extern void libpd_init();

    [DllImport("libpdcsharp", EntryPoint="libpd_bang")]
    private static extern int send_bang([In] [MarshalAs(UnmanagedType.LPStr)] string recv);

    [DllImport("libpdcsharp", EntryPoint="libpd_float")]
    private static extern  int send_float([In] [MarshalAs(UnmanagedType.LPStr)] string recv, float x);

    [DllImport("libpdcsharp", EntryPoint="libpd_symbol")]
    private static extern  int send_symbol([In] [MarshalAs(UnmanagedType.LPStr)] string recv, [In] [MarshalAs(UnmanagedType.LPStr)] string sym);

    [DllImport("libpdcsharp.dll", EntryPoint="libpd_getdollarzero")]
    private static extern  int getdollarzero(IntPtr p) ;

    public static int openFile( string filepath ) {
        if( !File.Exists(filepath) ) {
                throw new FileNotFoundException( filepath );
        }

        var ptr = openfile( Path.GetFileName(filepath), Path.GetDirectoryName(filepath) );

        if( ptr == IntPtr.Zero ) {
            throw new IOException( "unable to open patch " + filepath );
        }

        var handle = getdollarzero(ptr);

        OpenPatches[handle] = ptr;

        return handle;
    }

    public static void closeFile( int handle ) {
        if( !OpenPatches.ContainsKey( handle ) ) return false;
        var ptr = OpenPatches[handle];
        closefile( ptr );

        OpenPatches.Remove( handle );
    }

    public static void initPd() {

    }

    public static void startAudio() {

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