
#include "VideoViewController.h"
#include "iPhone_View.h"
#include "iPhone_OrientationSupport.h"

#include "objc/runtime.h"

static BOOL Video_ShouldAutorotateToInterfaceOrientationImpl(id self_, SEL _cmd, UIInterfaceOrientation interfaceOrientation);


@implementation UnityVideoViewController

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    extern void RequestNativeOrientation(ScreenOrientation targetOrient);

    RequestNativeOrientation(ConvertToUnityScreenOrientation(self.interfaceOrientation,0));
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        NSArray *array = touch.gestureRecognizers;
        for (UIGestureRecognizer *gesture in array)
        {
            if (gesture.enabled && [gesture isMemberOfClass:[UIPinchGestureRecognizer class]])
                gesture.enabled = NO;
        }
    }
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

+ (void)Initialize
{
    static bool _ClassInited = false;
    if(!_ClassInited)
    {
        if( UNITY_PRE_IOS6_SDK || !_ios60orNewer )
        {
            class_addMethod( [UnityVideoViewController class], @selector(shouldAutorotateToInterfaceOrientation:),
                             (IMP)Video_ShouldAutorotateToInterfaceOrientationImpl, "c12@0:4i8"
                           );
        }
        _ClassInited = true;
    }

}

@end

static BOOL Video_ShouldAutorotateToInterfaceOrientationImpl(id self_, SEL _cmd, UIInterfaceOrientation interfaceOrientation)
{
    EnabledOrientation targetAutorot = kAutorotateToPortrait;
    ScreenOrientation  targetRot = ConvertToUnityScreenOrientation(interfaceOrientation, &targetAutorot);
    ScreenOrientation  requestedOrientation = UnityRequestedScreenOrientation();

    if(requestedOrientation == autorotation)
        return UnityIsOrientationEnabled(targetAutorot);
    else
        return targetRot == requestedOrientation;
}
