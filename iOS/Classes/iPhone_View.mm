
#include "iPhone_View.h"
#include "UI/ActivityIndicator.h"
#include "UI/Keyboard.h"
#include "UI/SplashScreen.h"
#include "UI/UnityViewControllerBase.h"
#include "iPhone_OrientationSupport.h"
#include "Unity/DisplayManager.h"

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIApplication.h>

#include "objc/runtime.h"

static ScreenOrientation _curOrientation             = orientationUnknown;
static ScreenOrientation _nativeRequestedOrientation = orientationUnknown;

extern "C" __attribute__((visibility ("default"))) NSString * const kUnityViewWillRotate = @"kUnityViewWillRotate";
extern "C" __attribute__((visibility ("default"))) NSString * const kUnityViewDidRotate = @"kUnityViewDidRotate";

static DisplayConnection*   _mainDisplay     = nil;
static UIViewController*    _viewController = nil;

bool UnityUseAnimatedAutorotation();

void UnitySendTouchesBegin(NSSet* touches, UIEvent* event);
void UnitySendTouchesEnded(NSSet* touches, UIEvent* event);
void UnitySendTouchesCancelled(NSSet* touches, UIEvent* event);
void UnitySendTouchesMoved(NSSet* touches, UIEvent* event);

void UnityFinishRendering();



bool _shouldAttemptReorientation = false;

UIWindow*           UnityGetMainWindow()        { return _mainDisplay->window; }
UIViewController*   UnityGetGLViewController()  { return _viewController; }
UIView*             UnityGetGLView()            { return _mainDisplay->view; }
ScreenOrientation   UnityCurrentOrientation()   { return _curOrientation; }



void UnityStartActivityIndicator()
{
    ShowActivityIndicator(_mainDisplay->view);
}

void UnityStopActivityIndicator()
{
    HideActivityIndicator();
}

void CreateViewHierarchy()
{
    _mainDisplay = [[DisplayManager Instance] mainDisplay];
    [_mainDisplay->window makeKeyAndVisible];

    static bool _ClassInited = false;
    if(!_ClassInited)
    {
        AddOrientationSupportDefaultImpl([UnityViewController class]);
        _ClassInited = true;
    }

    _viewController = [[UnityViewController alloc] init];
    _viewController.wantsFullScreenLayout = TRUE;
    _viewController.view = _mainDisplay->view;

    [UIView setAnimationsEnabled:NO];

    ShowSplashScreen(_mainDisplay->window);

    NSNumber* style = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Unity_LoadingActivityIndicatorStyle"];
    ShowActivityIndicator([SplashScreen Instance], style ? [style intValue] : -1 );
}

void ReleaseViewHierarchy()
{
    HideActivityIndicator();
    HideSplashScreen();

    [_viewController release];
    _viewController = nil;

}

static void UpdateOrientationFromController(UIViewController* controller)
{
    ScreenOrientation orient = ConvertToUnityScreenOrientation(controller.interfaceOrientation,0);
    if(orient != _curOrientation)
    {
        _curOrientation = orient;

        UnitySetScreenOrientation(_curOrientation);
        if(_curOrientation != portrait)
            OrientTo(_curOrientation);
    }
}

void OnUnityInited()
{
    // set unity screen orientation, so first level awake get correct values
    UpdateOrientationFromController([SplashScreenController Instance]);
}

void OnUnityReady()
{
    UnityStopActivityIndicator();
    HideSplashScreen();

    [_mainDisplay->window addSubview: _mainDisplay->view];
    _mainDisplay->window.rootViewController = _viewController;
    [_mainDisplay->window bringSubviewToFront: _mainDisplay->view];

    // this is called after level was loaded, so some orientation constraints might have changed
    UpdateOrientationFromController(_viewController);

    [UIView setAnimationsEnabled: UnityUseAnimatedAutorotation()];
}

void NotifyAutoOrientationChange()
{
    _shouldAttemptReorientation = true;
}

static bool OrientationWillChangeSurfaceExtents( ScreenOrientation prevOrient, ScreenOrientation targetOrient )
{
    bool prevLandscape   = ( prevOrient == landscapeLeft || prevOrient == landscapeRight );
    bool targetLandscape = ( targetOrient == landscapeLeft || targetOrient == landscapeRight );

    return( prevLandscape != targetLandscape );
}

void OrientTo(int requestedOrient_)
{
    ScreenOrientation requestedOrient = (ScreenOrientation)requestedOrient_;

    extern bool _unityLevelReady;
    if(_unityLevelReady)
        UnityFinishRendering();

    [CATransaction begin];
    {
        [KeyboardDelegate StartReorientation];

        UnitySetScreenOrientation(requestedOrient);
        OrientView(_mainDisplay->view, requestedOrient);

        [UIApplication sharedApplication].statusBarOrientation = ConvertToIosScreenOrientation(requestedOrient);
    }
    [CATransaction commit];

    [CATransaction begin];
    [KeyboardDelegate FinishReorientation];
    [CATransaction commit];

    _curOrientation = requestedOrient;
}

// use it if you need to request native orientation change
// it is expected to be used with autorotation
// useful when you want to change unity orientation from overlaid view controller
void RequestNativeOrientation(ScreenOrientation targetOrient)
{
    _nativeRequestedOrientation = targetOrient;
}

void CheckOrientationRequest()
{
    ScreenOrientation requestedOrient = UnityRequestedScreenOrientation();
    if(requestedOrient == autorotation)
    {
        if(_ios50orNewer && _shouldAttemptReorientation)
            [UIViewController attemptRotationToDeviceOrientation];
        _shouldAttemptReorientation = false;
    }

    if(_nativeRequestedOrientation != orientationUnknown)
    {
        if(_nativeRequestedOrientation != _curOrientation)
            OrientTo(_nativeRequestedOrientation);
        _nativeRequestedOrientation = orientationUnknown;
    }
    else if(requestedOrient != autorotation)
    {
        if(requestedOrient != _curOrientation)
            OrientTo(requestedOrient);
    }
}

float ScreenScaleFactor()
{
    return [UIScreen mainScreen].scale;
}

void SetScreenFactorFromScreen(UIView* view)
{
    if( [view respondsToSelector:@selector(setContentScaleFactor:)] )
        [view setContentScaleFactor: ScreenScaleFactor()];
}

@implementation UnityViewController
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    _curOrientation = ConvertToUnityScreenOrientation(toInterfaceOrientation, 0);
    UnitySetScreenOrientation(_curOrientation);

    [[NSNotificationCenter defaultCenter] postNotificationName:kUnityViewWillRotate object:self];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUnityViewDidRotate object:self];

    extern bool _recreateMainView;
    if(_recreateMainView && self.view == _mainDisplay->view && [self.view isKindOfClass: [MainGLView class]])
    {
        extern void RecreateMainView();
        extern void UnityPlayerLoop();

        RecreateMainView();
        _recreateMainView = false;
        UnityPlayerLoop();
    }
}

@end

@implementation MainGLView
CGSize surfaceSize;

- (id) initWithFrame:(CGRect)frame
{
    if( (self = [super initWithFrame:frame]) )
    {
        [self setMultipleTouchEnabled:YES];
        [self setExclusiveTouch:YES];

        surfaceSize = frame.size;
    }
    return self;
}

- (void)layoutSubviews
{
    if (surfaceSize.width != self.bounds.size.width || surfaceSize.height != self.bounds.size.height)
    {
        surfaceSize = self.bounds.size;

        extern bool _recreateMainView;
        _recreateMainView = true;
    }
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UnitySendTouchesBegin(touches, event);
}
- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    UnitySendTouchesEnded(touches, event);
}
- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    UnitySendTouchesCancelled(touches, event);
}
- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    UnitySendTouchesMoved(touches, event);
}

@end
