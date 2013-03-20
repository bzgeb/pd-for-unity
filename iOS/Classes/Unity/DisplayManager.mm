
#include "DisplayManager.h"
#include "EAGLContextHelper.h"
#include "iPhone_View.h"

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

static DisplayManager* _DisplayManager = nil;

extern "C" void InitEAGLLayer(void* eaglLayer, bool use32bitColor);

@implementation DisplayConnection
{
    BOOL            needRecreateSurface;
    CGSize          requestedRenderingSize;
}

- (id)init:(UIScreen*)targetScreen
{
    if( (self = [super init]) )
    {
        self->screen = targetScreen;
        self->screenSize = targetScreen.currentMode.size;

        self->needRecreateSurface = NO;
        self->requestedRenderingSize = CGSizeMake(-1,-1);

        self->window = nil;
        self->view = nil;
        ::memset(&self->surface, 0x00, sizeof(UnityRenderingSurface));
    }
    return self;
}

- (id)createView:(BOOL)useWithGles
{
    return [self createView:useWithGles showRightAway:YES];
}
- (id)createView:(BOOL)useWithGles showRightAway:(BOOL)showRightAway;
{
    if(view == nil)
    {
        window = [[UIWindow alloc] initWithFrame: [screen bounds]];
        window.screen = screen;

        if(screen == [UIScreen mainScreen])
            view = [MainGLView alloc];
        else
            view = useWithGles ? [GLView alloc] : [UIView alloc];

        [view initWithFrame: [self->screen bounds]];
        view.contentScaleFactor = self->screen.scale;

        if(showRightAway)
        {
            [window addSubview:view];
            [window makeKeyAndVisible];
        }

        screenSize = [view.layer bounds].size;
        screenSize.width  = roundf(screenSize.width) * screen.scale;
        screenSize.height = roundf(screenSize.height) * screen.scale;
    }
    // TODO: create context here: for now we cant call it as we will query unity for target api
    /*
    if(surface.context == nil)
    {
        surface.layer = (CAEAGLLayer*)view.layer;
        surface.context = CreateContext([[DisplayManager Instance] mainDisplay]->surface.context);
    }
    */

    return self;
}

- (void)recreateSurface:(BOOL)use32bitColor
{
    [self recreateSurface:use32bitColor use24bitDepth:NO];
}
- (void)recreateSurface:(BOOL)use32bitColor use24bitDepth:(BOOL)use24bitDepth
{
    [self recreateSurface:use32bitColor use24bitDepth:use24bitDepth msaaSampleCount:0];
}
- (void)recreateSurface:(BOOL)use32bitColor use24bitDepth:(BOOL)use24bitDepth msaaSampleCount:(int)msaaSampleCount
{
    [self recreateSurface:use32bitColor use24bitDepth:use24bitDepth msaaSampleCount:msaaSampleCount renderW:-1 renderH:-1];
}
- (void)recreateSurface:(BOOL)use32bitColor use24bitDepth:(BOOL)use24bitDepth msaaSampleCount:(int)msaaSampleCount renderW:(int)renderW renderH:(int)renderH
{
    if(surface.context == nil)
    {
        surface.layer = (CAEAGLLayer*)view.layer;
        surface.context = CreateContext([[DisplayManager Instance] mainDisplay]->surface.context);
    }

    screenSize = [view.layer bounds].size;
    screenSize.width  = roundf(screenSize.width) * screen.scale;
    screenSize.height = roundf(screenSize.height) * screen.scale;

    bool systemSizeChanged  = screenSize.width != surface.systemW || screenSize.height != surface.systemH;
    bool msaaChanged        = (surface.msaaSamples != msaaSampleCount && _supportsMSAA);
    bool colorfmtChanged    = use32bitColor != surface.use32bitColor;
    bool depthfmtChanged    = surface.use24bitDepth != use24bitDepth;

    bool renderSizeChanged  = false;
    if(     (renderW > 0 && surface.targetW != renderW)             // changed resolution
        ||  (renderH > 0 && surface.targetH != renderH)             // changed resolution
        ||  (renderW <= 0 && surface.targetW != surface.systemW)    // no longer need intermediate fb
        ||  (renderH <= 0 && surface.targetH != surface.systemH)    // no longer need intermediate fb
      )
    {
        renderSizeChanged = true;
    }

    bool recreateSystemSurface      = (surface.systemFB == 0) || systemSizeChanged || colorfmtChanged;
    bool recreateRenderingSurface   = renderSizeChanged || msaaChanged || colorfmtChanged;
    bool recreateDepthbuffer        = systemSizeChanged || renderSizeChanged || msaaChanged || depthfmtChanged;


    surface.use32bitColor = use32bitColor;
    surface.use24bitDepth = use24bitDepth;

    surface.systemW = screenSize.width;
    surface.systemH = screenSize.height;

    surface.targetW = renderW > 0 ? renderW : surface.systemW;
    surface.targetH = renderH > 0 ? renderH : surface.systemH;

    surface.msaaSamples = _supportsMSAA ? msaaSampleCount : 0;

    if(recreateSystemSurface)
        CreateSystemRenderingSurface(&surface);
    if(recreateRenderingSurface)
        CreateRenderingSurface(&surface);
    if(recreateDepthbuffer)
        CreateSharedDepthbuffer(&surface);
    if(recreateSystemSurface || recreateRenderingSurface || recreateDepthbuffer)
        CreateUnityRenderBuffers(&surface);
}

- (void)dealloc
{
    if(surface.context != nil)
    {
        DestroySystemRenderingSurface(&surface);
        DestroyRenderingSurface(&surface);
        DestroySharedDepthbuffer(&surface);
        DestroyUnityRenderBuffers(&surface);

        [surface.context release];
        surface.context = nil;
        surface.layer   = nil;

        ::memset(&self->surface, 0x00, sizeof(UnityRenderingSurface));
    }

    [view release];
    view = nil;

    [window release];
    window = nil;

    [super dealloc];
}

- (void)present
{
    if(surface.context != nil)
    {
        PreparePresentRenderingSurface(&surface, [[DisplayManager Instance] mainDisplay]->surface.context);

        EAGLContextSetCurrentAutoRestore autorestore(surface.context);
        GLES_CHK(glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface.systemColorRB));
        [surface.context presentRenderbuffer:GL_RENDERBUFFER_OES];

        if(needRecreateSurface)
        {
            [self   recreateSurface:surface.use32bitColor use24bitDepth:surface.use24bitDepth msaaSampleCount:surface.msaaSamples
                    renderW:(int)requestedRenderingSize.width renderH:(int)requestedRenderingSize.height
            ];

            needRecreateSurface = NO;
            requestedRenderingSize = CGSizeMake(surface.targetW, surface.targetH);
        }
    }
}


- (void)requestRenderingResolution:(CGSize)res
{
    requestedRenderingSize = res;
    needRecreateSurface    = YES;
}
@end


@implementation DisplayManager

- (id)init
{
    if( (self = [super init]) )
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(screenDidConnect:)
                                              name:UIScreenDidConnectNotification
                                              object:nil
        ];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(screenDidDisconnect:)
                                              name:UIScreenDidDisconnectNotification
                                              object:nil
        ];

        displayConnection = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
        [[UIScreen screens] enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL* stop) {
            NSValue* key = [NSValue valueWithPointer:(UIScreen*)object];
            NSValue* val = [NSValue valueWithPointer: [[DisplayConnection alloc] init:(UIScreen*)object]];
            [displayConnection setObject:val forKey:key];
        }];

        mainDisplay = [self display:[UIScreen mainScreen]];
    }
    return self;
}

- (int)displayCount
{
    return displayConnection.count;
}

- (DisplayConnection*)mainDisplay
{
    return mainDisplay;
}

- (BOOL)displayAvailable:(UIScreen*)targetScreen;
{
    return [self display:targetScreen] != nil;
}

- (DisplayConnection*)display:(UIScreen*)targetScreen
{
    NSValue* key = [NSValue valueWithPointer:targetScreen];
    NSValue* val = [displayConnection objectForKey:key];

    return val ? (DisplayConnection*)(val.pointerValue) : nil;
}

- (void)updateDisplayListInUnity
{
    extern void UnityUpdateDisplayList();
    UnityUpdateDisplayList();
}

- (void)presentAll
{
    [displayConnection enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        void* conn = ((NSValue*)obj).pointerValue;
        [(DisplayConnection*)conn present];
    }];
}

- (void)presentAllButMain
{
    [displayConnection enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        void* conn = ((NSValue*)obj).pointerValue;
        if((DisplayConnection*)conn != [self mainDisplay])
            [(DisplayConnection*)conn present];
    }];
}


- (void)screenDidConnect:(NSNotification*)notification
{
    UIScreen* screen = (UIScreen*)[notification object];

    NSValue* key = [NSValue valueWithPointer: screen];
    NSValue* val = [NSValue valueWithPointer: [[DisplayConnection alloc] init:screen]];
    [displayConnection setObject:val forKey:key];

    [self updateDisplayListInUnity];
}

- (void)screenDidDisconnect:(NSNotification*)notification
{
    UIScreen* screen = (UIScreen*)[notification object];

    // first of all disable rendering to these buffers
    {
        DisplayConnection* conn = [[DisplayManager Instance] display:screen];
        if(conn->surface.systemFB != 0)
        {
            extern void UnityDisableRenderBuffers(void*, void*);
            UnityDisableRenderBuffers(conn->surface.unityColorBuffer, conn->surface.unityDepthBuffer);
        }
    }



    NSValue* key = [NSValue valueWithPointer:screen];
    NSValue* val = [displayConnection objectForKey:key];
    if(val != nil)
    {
        [(DisplayConnection*)val.pointerValue release];
        [displayConnection removeObjectForKey:key];
    }

    [self updateDisplayListInUnity];
}

+ (void)Initialize
{
    NSAssert(_DisplayManager == nil, @"[DisplayManager Initialize] called after creating handler");
    if(!_DisplayManager)
        _DisplayManager = [[DisplayManager alloc] init];
}

+ (DisplayManager*)Instance
{
    if(!_DisplayManager)
        _DisplayManager = [[DisplayManager alloc] init];

    return _DisplayManager;
}

@end

//==============================================================================
//
//  Unity Interface:

static void EnsureDisplayIsInited(DisplayConnection* conn)
{
    // main screen view will be created in AppController,
    // so we can assume that we need to init secondary display from script
    // meaning: gles + show right away

    if(conn->view == nil)
        [conn createView:YES];

    // careful here: we dont want to trigger surface recreation
    if(conn->surface.systemFB == 0)
    {
        extern bool UnityUse32bitDisplayBuffer();
        extern bool UnityUse24bitDepthBuffer();
        [conn recreateSurface:UnityUse32bitDisplayBuffer() use24bitDepth:UnityUse24bitDepthBuffer()];
    }

}

int UnityDisplayManager_DisplayCount()
{
    return [[DisplayManager Instance] displayCount];
}

bool UnityDisplayManager_DisplayAvailable(void* nativeDisplay)
{
    return [[DisplayManager Instance] displayAvailable:(UIScreen*)nativeDisplay];
}

void UnityDisplayManager_DisplaySystemResolution(void* nativeDisplay, int* w, int* h)
{
    DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
    EnsureDisplayIsInited(conn);

    *w = (int)conn->surface.systemW;
    *h = (int)conn->surface.systemH;
}

void UnityDisplayManager_DisplayRenderingResolution(void* nativeDisplay, int* w, int* h)
{
    DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
    EnsureDisplayIsInited(conn);

    *w = (int)conn->surface.targetW;
    *h = (int)conn->surface.targetH;
}

void UnityDisplayManager_DisplayRenderingBuffers(void* nativeDisplay, void** colorBuffer, void** depthBuffer)
{
    DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
    EnsureDisplayIsInited(conn);

    if(colorBuffer) *colorBuffer = conn->surface.unityColorBuffer;
    if(depthBuffer) *depthBuffer = conn->surface.unityDepthBuffer;
}

void UnityDisplayManager_SetRenderingResolution(void* nativeDisplay, int w, int h)
{
    DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
    EnsureDisplayIsInited(conn);

    if((UIScreen*)nativeDisplay == [UIScreen mainScreen])
    {
        extern void UnityRequestRenderingResolution(unsigned, unsigned);
        UnityRequestRenderingResolution(w,h);
    }
    else
    {
        [conn requestRenderingResolution:CGSizeMake(w,h)];
    }
}

extern "C" const UnityRenderingSurface* UnityDisplayManager_MainDisplayRenderingSurface()
{
    return &[[DisplayManager Instance] mainDisplay]->surface;
}


