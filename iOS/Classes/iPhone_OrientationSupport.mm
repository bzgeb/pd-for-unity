#include "iPhone_OrientationSupport.h"


CGAffineTransform TransformForOrientation( ScreenOrientation orient )
{
    switch(orient)
    {
        case portrait:              return CGAffineTransformIdentity;
        case portraitUpsideDown:    return CGAffineTransformMakeRotation(M_PI);
        case landscapeLeft:         return CGAffineTransformMakeRotation(M_PI_2);
        case landscapeRight:        return CGAffineTransformMakeRotation(-M_PI_2);

        default:                    return CGAffineTransformIdentity;
    }
    return CGAffineTransformIdentity;
}

CGRect ContentRectForOrientation( ScreenOrientation orient )
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];

    switch(orient)
    {
        case portrait:
        case portraitUpsideDown:
            return screenRect;
        case landscapeLeft:
        case landscapeRight:
            return CGRectMake(screenRect.origin.y, screenRect.origin.x, screenRect.size.height, screenRect.size.width);
        default:
            return screenRect;
    }

    return screenRect;
}

UIInterfaceOrientation ConvertToIosScreenOrientation(ScreenOrientation orient)
{
    switch( orient )
    {
        case portrait:              return UIInterfaceOrientationPortrait;
        case portraitUpsideDown:    return UIInterfaceOrientationPortraitUpsideDown;
        // landscape left/right have switched values in device/screen orientation
        // though unity docs are adjusted with device orientation values, so swap here
        case landscapeLeft:         return UIInterfaceOrientationLandscapeRight;
        case landscapeRight:        return UIInterfaceOrientationLandscapeLeft;

        default:                    return UIInterfaceOrientationPortrait;
    }

    return UIInterfaceOrientationPortrait;
}

ScreenOrientation ConvertToUnityScreenOrientation(UIInterfaceOrientation hwOrient, EnabledOrientation* outAutorotOrient)
{
    EnabledOrientation autorotOrient     = kAutorotateToPortrait;
    ScreenOrientation  unityScreenOrient = portrait;

    switch (hwOrient)
    {
        case UIInterfaceOrientationPortrait:
            autorotOrient     = kAutorotateToPortrait;
            unityScreenOrient = portrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            autorotOrient     = kAutorotateToPortraitUpsideDown;
            unityScreenOrient = portraitUpsideDown;
            break;
        // landscape left/right have switched values in device/screen orientation
        // though unity docs are adjusted with device orientation values, so swap here
        case UIInterfaceOrientationLandscapeLeft:
            autorotOrient     = kAutorotateToLandscapeRight;
            unityScreenOrient = landscapeRight;
            break;
        case UIInterfaceOrientationLandscapeRight:
            autorotOrient     = kAutorotateToLandscapeLeft;
            unityScreenOrient = landscapeLeft;
            break;
    }

    if (outAutorotOrient)
        *outAutorotOrient = autorotOrient;

    return unityScreenOrient;
}

ScreenOrientation QueryInitialOrientation(UIViewController* root)
{
    ScreenOrientation ret = orientationUnknown;

    NSString* initialOrientation = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIInterfaceOrientation"];
    if( [initialOrientation isEqualToString: @"UIInterfaceOrientationPortrait"] == YES )
        ret = portrait;
    else if( [initialOrientation isEqualToString: @"UIInterfaceOrientationPortraitUpsideDown"] == YES )
        ret = portraitUpsideDown;
    else if( [initialOrientation isEqualToString: @"UIInterfaceOrientationLandscapeLeft"] == YES )
        ret = landscapeRight;
    else if( [initialOrientation isEqualToString: @"UIInterfaceOrientationLandscapeRight"] == YES )
        ret = landscapeLeft;

    if(ret == orientationUnknown)
        ret = ConvertToUnityScreenOrientation(root.interfaceOrientation, 0);

    return ret;
}

void OrientView(UIView* view, ScreenOrientation target)
{
    view.transform  = TransformForOrientation(target);
    view.bounds     = ContentRectForOrientation(target);
}
