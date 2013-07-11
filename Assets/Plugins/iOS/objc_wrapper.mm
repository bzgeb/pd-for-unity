#import "PdBase.h"
#import "PdDispatcher.h"
#import "PdAudioController.h"
#import "Listener.h"

extern "C" {
//    extern void lrshift_tilde_setup(void);
//    extern void argument_setup(void);
//    extern void phasorshot_tilde_setup(void);
//    extern void path_setup(void);
//    extern void soundfile_info_setup(void);
//    extern void expr_tilde_setup(void);
//    extern void demultiplex_setup(void);
//    extern void iem_send_setup(void);
//    extern void prepend_setup(void);
//    extern void avg_tilde_setup(void);
//    extern void tosymbol_setup(void);
//    extern void pong_tilde_setup(void);
//    extern void fiddle_tilde_setup(void);
//    extern void record_tilde_setup(void);
//    extern void switch_setup(void);
    
    static PdDispatcher* dispatcher;
    
    static NSMutableDictionary* openFiles;
    
    static PdAudioController* audioController;
    
    int _openFile( char * filename, int length )
    {
        NSString* file = [[NSString alloc] initWithData:[NSData dataWithBytes:filename length:length] encoding:NSUTF16LittleEndianStringEncoding];
        NSLog(@"Opening File: %@", file);
        
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        
        NSString* fullPath = [resourcePath stringByAppendingPathComponent:file];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fullPath];
        NSLog(@"File Exists: %d", fileExists);
        
        NSValue *filePointer = [NSValue valueWithPointer:[PdBase openFile:file path:resourcePath]];
        int handle = [PdBase dollarZeroForFile: [filePointer pointerValue]];
        
        [openFiles setObject:filePointer forKey:[NSNumber numberWithInt:handle]];
        
        [file release];

        return handle;
    }
    
    void _closeFile( int handle )
    {
//       NSString* file = [[NSString alloc] initWithData:[NSData dataWithBytes:filename length:length] encoding:NSUTF16LittleEndianStringEncoding];
       
       void * filePointer = [[openFiles objectForKey:[NSNumber numberWithInt:handle]] pointerValue];
       
       [PdBase closeFile:filePointer];
       [openFiles removeObjectForKey:[NSNumber numberWithInt:handle]];
    }
    
    void _initPd(float newSampleRate, int ticks, int inputChannels, int outputChannels)
    {
        // load our audio controller
        audioController = [[PdAudioController alloc] init];
        [audioController configureAmbientWithSampleRate:44100 numberChannels:2 mixingEnabled:YES];
        
//        dispatcher = [[PdDispatcher alloc] init];
        dispatcher = [[LoggingDispatcher alloc] init];
        
        openFiles = [[NSMutableDictionary alloc] init];
        
        [PdBase setDelegate:dispatcher];
        
//        lrshift_tilde_setup();
//        argument_setup();
//        phasorshot_tilde_setup();
//        path_setup();
//        soundfile_info_setup();
//        expr_tilde_setup();
//        demultiplex_setup();
//        iem_send_setup();
//        prepend_setup();
//        tosymbol_setup();
//        avg_tilde_setup();
//        pong_tilde_setup();
//        fiddle_tilde_setup();
//        record_tilde_setup();
//        switch_setup();
        [audioController print];
    }
    
    void _startAudio()
    {
        [audioController setActive:YES];
    }

    void _stopAudio()
    {
        [audioController setActive:NO];
    }

    void _pauseAudio()
    {
        _stopAudio();
    }
    
    void _sendBangToReceiver(char * receiver, int length)
    {
        NSString* rec = [[NSString alloc] initWithData:[NSData dataWithBytes:receiver length:length] encoding:NSUTF16LittleEndianStringEncoding];
        
        [PdBase sendBangToReceiver:rec];
        
        [rec release];
    }
    
    void _sendFloat(const float value, char * receiver, int length)
    {
        NSString* rec = [[NSString alloc] initWithData:[NSData dataWithBytes:receiver length:length] encoding:NSUTF16LittleEndianStringEncoding];
        
        [PdBase sendFloat:value toReceiver:rec];
        
        [rec release];
    }
    
    void * _subscribe(char * symbol, int symLength, char * gameObject, int objLength, char * methodName, int methLength)
    {
        NSString* sym  = [[NSString alloc] initWithData:[NSData dataWithBytes:symbol     length:symLength]  encoding:NSUTF16LittleEndianStringEncoding];
        NSString* obj  = [[NSString alloc] initWithData:[NSData dataWithBytes:gameObject length:objLength]  encoding:NSUTF16LittleEndianStringEncoding];
        NSString* meth = [[NSString alloc] initWithData:[NSData dataWithBytes:methodName length:methLength] encoding:NSUTF16LittleEndianStringEncoding];
        
        Listener* newListener = [[Listener alloc] init];
        [newListener setUnityObject:obj];
        [newListener setUnityMethod:meth];
        
        [dispatcher addListener:newListener forSource:sym];
        
        void * subscription = [PdBase subscribe:sym];
        [sym release];
        return subscription;
    }
    
    void _unsubscribe(void * subscription)
    {
        [PdBase unsubscribe:subscription];
    }
    
    void _sendSymbolToReceiver(char * symbol, int symLength, char * receiver, int recLength)
    {
        NSString * _receiver = [[NSString alloc] initWithData:[NSData dataWithBytes:receiver length:recLength] encoding:NSUTF16LittleEndianStringEncoding];
        NSString * _symbol   = [[NSString alloc] initWithData:[NSData dataWithBytes:symbol   length:symLength] encoding:NSUTF16LittleEndianStringEncoding];
        
        [PdBase sendSymbol:_symbol toReceiver:_receiver];
        
        [_symbol release];
        [_receiver release];
    }
    
    void _sendMessageToReceiver(char * message, int messageLength, char * arguments, int argumentsLength, char * receiver, int recLength)
    {
        NSString * _receiver  = [[NSString alloc] initWithData:[NSData dataWithBytes:receiver  length:recLength]       encoding:NSUTF16LittleEndianStringEncoding];
        NSString * _message   = [[NSString alloc] initWithData:[NSData dataWithBytes:message   length:messageLength]   encoding:NSUTF16LittleEndianStringEncoding];
        NSString * _arguments = [[NSString alloc] initWithData:[NSData dataWithBytes:arguments length:argumentsLength] encoding:NSUTF16LittleEndianStringEncoding];
        
//        NSArray * argumentList = [_arguments componentsSeparatedByString:@":"];
        
        NSMutableArray * argumentList = [[[_arguments componentsSeparatedByString:@":"] mutableCopy] autorelease];
        
        for (int c = 0; c < [argumentList count]; ++c) {
            NSString * arg = [argumentList objectAtIndex:c];
            if ([arg rangeOfString:@"%f"].location != NSNotFound) {
                [argumentList replaceObjectAtIndex:c withObject:[NSNumber numberWithFloat:[arg floatValue]]];
            }
        }
        
        NSLog(@"String: %@", _arguments);
        NSLog(@"Array: %@", argumentList);
        
        [PdBase sendMessage:_message withArguments:argumentList toReceiver:_receiver];
        
        [_message release];
        [_receiver release];
        [_arguments release];
    }
    
    void _sendListToReceiver(char * arguments, int argumentsLength, char * receiver, int recLength)
    {
        NSString * _receiver  = [[NSString alloc] initWithData:[NSData dataWithBytes:receiver  length:recLength]       encoding:NSUTF16LittleEndianStringEncoding];
        NSString * _arguments = [[NSString alloc] initWithData:[NSData dataWithBytes:arguments length:argumentsLength] encoding:NSUTF16LittleEndianStringEncoding];
        NSMutableArray * argumentList = [[[_arguments componentsSeparatedByString:@":"] mutableCopy] autorelease];
        
        for (int c = 0; c < [argumentList count]; ++c) {
            NSString * arg = [argumentList objectAtIndex:c];
            if ([arg rangeOfString:@"%f"].location != NSNotFound) {
                [argumentList replaceObjectAtIndex:c withObject:[NSNumber numberWithFloat:[arg floatValue]]];
            }
        }
        
        NSLog(@"String: %@", _arguments);
        NSLog(@"Array: %@", argumentList);
        
        [PdBase sendList:argumentList toReceiver:_receiver];
        
        [_arguments release];
        [_receiver release];
    }
}
