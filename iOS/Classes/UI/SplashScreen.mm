
#include "SplashScreen.h"
#include "iPhone_View.h"
#include "iPhone_OrientationSupport.h"

#include "objc/runtime.h"
#include <stdlib.h>

static SplashScreen*            _splash      = nil;
static SplashScreenController*  _controller  = nil;
static ScreenOrientation        _curOrient   = orientationUnknown;

static void OrientSplashPhone();

@implementation SplashScreen

- (id) initWithFrame:(CGRect)frame
{
    if( (self = [super initWithFrame:frame]) )
    {
        splashImageOrient = orientationUnknown;
    }
    return self;
}

- (void)unloadImage;
{
    if(self.image)
    {
        [self.image release];
        self.image = nil;
    }
}

- (void)updateOrientation:(ScreenOrientation)orient
{
    bool need2xSplash = ScreenScaleFactor() > 1.0f;

    bool needOrientedSplash = false;
    bool needPortraitSplash = true;

    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone)
    {
        bool devicePortrait  = UIDeviceOrientationIsPortrait(orient);
        bool deviceLandscape = UIDeviceOrientationIsLandscape(orient);

        NSArray* supportedOrientation = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UISupportedInterfaceOrientations"];
        bool rotateToPortrait  =   [supportedOrientation containsObject: @"UIInterfaceOrientationPortrait"]
                                || [supportedOrientation containsObject: @"UIInterfaceOrientationPortraitUpsideDown"];
        bool rotateToLandscape =   [supportedOrientation containsObject: @"UIInterfaceOrientationLandscapeLeft"]
                                || [supportedOrientation containsObject: @"UIInterfaceOrientationLandscapeRight"];


        needOrientedSplash = true;
        if (devicePortrait && rotateToPortrait)
            needPortraitSplash = true;
        else if (deviceLandscape && rotateToLandscape)
            needPortraitSplash = false;
        else if (rotateToPortrait)
            needPortraitSplash = true;
        else
            needPortraitSplash = false;
    }

    const char* portraitSuffix  = needOrientedSplash ? "-Portrait" : "";
    const char* landscapeSuffix = needOrientedSplash ? "-Landscape" : "";

    const char* szSuffix        = need2xSplash ? "@2x" : "";
    const char* orientSuffix    = needPortraitSplash ? portraitSuffix : landscapeSuffix;

    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        if([[UIScreen mainScreen] bounds].size.height == 568)
            orientSuffix = "-568h";
    }

    // we will use imageWithContentsOfFile so we need fully qualified path
    // we need to retain path because seems like imageWithContentsOfFile will be done on another thread
    // so we need to preserve path to be used with it until next runloop
    NSString* imageName = [NSString stringWithFormat:@"Default%s%s", orientSuffix, szSuffix];
    NSString* imagePath = [[[[NSBundle mainBundle] pathForResource: imageName ofType: @"png"] retain] autorelease];

    [self unloadImage];
    self.image = [[UIImage imageWithContentsOfFile: imagePath] retain];

    splashImageOrient = orient;
}

+ (SplashScreen*)Instance
{
    return _splash;
}

@end

@implementation SplashScreenController

- (void)create:(UIWindow*)window
{
    _splash   = [[SplashScreen alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    _curOrient = orientationUnknown;

    SetScreenFactorFromScreen(_splash);
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone)
    {
        _splash.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _splash.autoresizesSubviews = YES;
    }
    self.view = _splash;

    self.wantsFullScreenLayout = TRUE;

    [window addSubview: _splash];
    window.rootViewController = self;
    [window bringSubviewToFront: _splash];

    if(_curOrient == orientationUnknown)
        _curOrient = QueryInitialOrientation(self);

    [_splash updateOrientation: _curOrient];

    ScreenOrientation viewOrient = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? portrait : _curOrient;
    _splash.transform = TransformForOrientation(viewOrient);
    _splash.bounds = ContentRectForOrientation(viewOrient);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    _curOrient = ConvertToUnityScreenOrientation(toInterfaceOrientation, 0);
    if(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone)
        [_splash updateOrientation: _curOrient];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        _splash.transform = TransformForOrientation(portrait);
        _splash.bounds = [[UIScreen mainScreen] bounds];
    }
}

- (BOOL)shouldAutorotate
{
    return UnityRequestedScreenOrientation() == autorotation;
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

+ (SplashScreenController*)Instance
{
    return _controller;
}

@end

static BOOL Splash_ShouldAutorotateToInterfaceOrientationImpl(id self_, SEL _cmd, UIInterfaceOrientation interfaceOrientation)
{
    assert([self_ isKindOfClass:[SplashScreenController class]]);

    EnabledOrientation targetAutorot        = kAutorotateToPortrait;
    ScreenOrientation  targetOrient         = ConvertToUnityScreenOrientation(interfaceOrientation, &targetAutorot);
    ScreenOrientation  requestedOrientation = UnityRequestedScreenOrientation();

    if(requestedOrientation != autorotation)
        return requestedOrientation == targetOrient;

    return UnityIsOrientationEnabled(targetAutorot);
}

void ShowSplashScreen(UIWindow* window)
{
    static bool _ClassInited = false;
    if(!_ClassInited)
    {
        if( UNITY_PRE_IOS6_SDK || !_ios60orNewer )
        {
            class_addMethod( [SplashScreenController class], @selector(shouldAutorotateToInterfaceOrientation:),
                             (IMP)Splash_ShouldAutorotateToInterfaceOrientationImpl, "c12@0:4i8"
                           );
        }
        _ClassInited = true;
    }

    _controller = [[SplashScreenController alloc] init];
    [_controller create:window];
}

void HideSplashScreen()
{
    if(_splash)
    {
        [_splash removeFromSuperview];
        [_splash unloadImage];
        [_splash release];
        _splash = nil;
    }
    if(_controller)
    {
        [_controller release];
        _controller = nil;
    }
}
