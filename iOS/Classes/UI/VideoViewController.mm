
#include "VideoViewController.h"
#include "UnityViewControllerBase.h"
#include "iPhone_OrientationSupport.h"

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

+ (void)Initialize
{
    static bool _ClassInited = false;
    if(!_ClassInited)
    {
        AddOrientationSupportDefaultImpl([UnityVideoViewController class]);
        _ClassInited = true;
    }
}

@end
