
#include "iPhone_View.h"
#include "UI/SplashScreen.h"
#include "UI/ActivityIndicator.h"
#include "iPhone_OrientationSupport.h"

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIApplication.h>

#include "objc/runtime.h"

static ScreenOrientation _curOrientation             = orientationUnknown;
static ScreenOrientation _nativeRequestedOrientation = orientationUnknown;

extern "C" __attribute__((visibility ("default"))) NSString * const kUnityViewWillRotate = @"kUnityViewWillRotate";
extern "C" __attribute__((visibility ("default"))) NSString * const kUnityViewDidRotate = @"kUnityViewDidRotate";

static BOOL ShouldAutorotateToInterfaceOrientationImpl(id self, SEL _cmd, UIInterfaceOrientation interfaceOrientation);

struct EAGLSurfaceDesc;
extern EAGLSurfaceDesc _surface;
void RecreateSurface(EAGLSurfaceDesc* surface, bool insideRepaint);


bool UnityUseAnimatedAutorotation();
void UnityKeyboardOrientationStep1();
void UnityKeyboardOrientationStep2();

void UnitySendTouchesBegin(NSSet* touches, UIEvent* event);
void UnitySendTouchesEnded(NSSet* touches, UIEvent* event);
void UnitySendTouchesCancelled(NSSet* touches, UIEvent* event);
void UnitySendTouchesMoved(NSSet* touches, UIEvent* event);

void UnityFinishRendering();

static UIWindow*                _window             = nil;
static UIViewController*        _viewController     = nil;
static EAGLView*                _view               = nil;

bool _shouldAttemptReorientation = false;

UIWindow*           UnityGetMainWindow()        { return _window; }
UIViewController*   UnityGetGLViewController()  { return _viewController; }
UIView*             UnityGetGLView()            { return _view; }
ScreenOrientation   UnityCurrentOrientation()   { return _curOrientation; }



void UnityStartActivityIndicator()
{
    ShowActivityIndicator(_view);
}

void UnityStopActivityIndicator()
{
    HideActivityIndicator();
}

void CreateViewHierarchy()
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];

    _window = [[UIWindow alloc] initWithFrame: screenRect];
    [_window makeKeyAndVisible];

    _view   = [[EAGLView alloc] initWithFrame: screenRect];
    SetScreenFactorFromScreen(_view);

    if( UNITY_PRE_IOS6_SDK || !_ios60orNewer )
    {
        class_addMethod( [UnityViewController class], @selector(shouldAutorotateToInterfaceOrientation:),
                         (IMP)ShouldAutorotateToInterfaceOrientationImpl, "c12@0:4i8"
                       );
    }
    _viewController = [[UnityViewController alloc] init];
    _viewController.wantsFullScreenLayout = TRUE;
    _viewController.view = _view;

    [UIView setAnimationsEnabled:NO];
    ShowSplashScreen(_window);
}

void ReleaseViewHierarchy()
{
    HideActivityIndicator();
    HideSplashScreen();

    [_viewController release];
    _viewController = nil;

    [_view release];
    _view = nil;

    [_window release];
    _window = nil;
}

static void UpdateOrientationFromController(UIViewController* controller)
{
    UIInterfaceOrientation orientIOS = controller.interfaceOrientation;
    ScreenOrientation orient = ConvertToUnityScreenOrientation(orientIOS,0);

    if( _curOrientation != orient )
    {
        _curOrientation = orient;
        UnitySetScreenOrientation(_curOrientation);
        if(_curOrientation != portrait)
            OrientTo(_curOrientation);
    }
}


void OnUnityStartLoading()
{
    UpdateOrientationFromController([SplashScreenController Instance]);
    ShowActivityIndicator([SplashScreen Instance]);
}

void OnUnityReady()
{
    UnityStopActivityIndicator();
    HideSplashScreen();

    [_window addSubview: _view];
    _window.rootViewController = _viewController;
    [_window bringSubviewToFront: _view];

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
        UnityKeyboardOrientationStep1();

        UnitySetScreenOrientation(requestedOrient);
        OrientView(_view, requestedOrient);

        [UIApplication sharedApplication].statusBarOrientation = ConvertToIosScreenOrientation(requestedOrient);
    }
    [CATransaction commit];

    [CATransaction begin];
    UnityKeyboardOrientationStep2();
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
    return [[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [UIScreen mainScreen].scale : 1.0f;
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
}

- (BOOL)shouldAutorotate
{
    return (UnityRequestedScreenOrientation() == autorotation);
}

- (NSUInteger)supportedInterfaceOrientations
{
    NSUInteger ret = 0;

    // TODO: get rid of copy paste of orientation related code
    if(UnityRequestedScreenOrientation() == autorotation)
    {
        if( UnityIsOrientationEnabled(kAutorotateToPortrait) )              ret |= (1 << UIInterfaceOrientationPortrait);
        if( UnityIsOrientationEnabled(kAutorotateToPortraitUpsideDown) )    ret |= (1 << UIInterfaceOrientationPortraitUpsideDown);
        if( UnityIsOrientationEnabled(kAutorotateToLandscapeLeft) )         ret |= (1 << UIInterfaceOrientationLandscapeRight);
        if( UnityIsOrientationEnabled(kAutorotateToLandscapeRight) )        ret |= (1 << UIInterfaceOrientationLandscapeLeft);
    }
    else
    {
        switch(UnityRequestedScreenOrientation())
        {
            case portrait:              ret = (1 << UIInterfaceOrientationPortrait);            break;
            case portraitUpsideDown:    ret = (1 << UIInterfaceOrientationPortraitUpsideDown);  break;
            case landscapeLeft:         ret = (1 << UIInterfaceOrientationLandscapeRight);      break;
            case landscapeRight:        ret = (1 << UIInterfaceOrientationLandscapeLeft);       break;
            default:                    ret = (1 << UIInterfaceOrientationPortrait);            break;
        }
    }

    return ret;
}
@end

static BOOL ShouldAutorotateToInterfaceOrientationImpl(id self, SEL _cmd, UIInterfaceOrientation interfaceOrientation)
{
    EnabledOrientation targetAutorot   = kAutorotateToPortrait;
    ScreenOrientation  targetOrient    = ConvertToUnityScreenOrientation(interfaceOrientation, &targetAutorot);
    ScreenOrientation  requestedOrientation = UnityRequestedScreenOrientation();

    if (requestedOrientation != autorotation)
        return (requestedOrientation == targetOrient);

    return UnityIsOrientationEnabled(targetAutorot);
}


@implementation EAGLView

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

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
        extern bool _recreateSurface;
        _recreateSurface = true;

        surfaceSize = self.bounds.size;
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
