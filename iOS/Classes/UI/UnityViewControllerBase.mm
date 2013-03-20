
#include "UnityViewControllerBase.h"
#include "iPhone_Common.h"
#include "iPhone_OrientationSupport.h"

#include "objc/runtime.h"


BOOL
ShouldAutorotateToInterfaceOrientation_DefaultImpl(id self_, SEL _cmd, UIInterfaceOrientation interfaceOrientation)
{
    EnabledOrientation targetAutorot = kAutorotateToPortrait;
    ScreenOrientation  targetRot = ConvertToUnityScreenOrientation(interfaceOrientation, &targetAutorot);
    ScreenOrientation  requestedOrientation = UnityRequestedScreenOrientation();

    if(requestedOrientation == autorotation)
        return UnityIsOrientationEnabled(targetAutorot);
    else
        return targetRot == requestedOrientation;
}

NSUInteger
SupportedInterfaceOrientations_DefaultImpl(id self_, SEL _cmd)
{
    NSUInteger ret = 0;

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

BOOL
ShouldAutorotate_DefaultImpl(id self_, SEL _cmd)
{
    return (UnityRequestedScreenOrientation() == autorotation);
}

void
AddShouldAutorotateToImplIfNeeded(Class targetClass, BOOL (*impl)(id, SEL, UIInterfaceOrientation))
{
    if( UNITY_PRE_IOS6_SDK || !_ios60orNewer )
        class_addMethod( targetClass, @selector(shouldAutorotateToInterfaceOrientation:), (IMP)impl, "c12@0:4i8" );
}

void
AddOrientationSupportDefaultImpl(Class targetClass)
{
    AddShouldAutorotateToImplIfNeeded( targetClass, &ShouldAutorotateToInterfaceOrientation_DefaultImpl );

    class_addMethod( targetClass, @selector(supportedInterfaceOrientations),
                     (IMP)SupportedInterfaceOrientations_DefaultImpl, "I8@0:4"
                   );
    class_addMethod( targetClass, @selector(shouldAutorotate),
                     (IMP)ShouldAutorotate_DefaultImpl, "c8@0:4"
                   );
}
