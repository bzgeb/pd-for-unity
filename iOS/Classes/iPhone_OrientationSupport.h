
#ifndef _TRAMPOLINE_IPHONE_ORIENTATIONSUPPORT_H_
#define _TRAMPOLINE_IPHONE_ORIENTATIONSUPPORT_H_

#import <QuartzCore/QuartzCore.h>
#include "iPhone_Common.h"


enum EnabledOrientation
{
    kAutorotateToPortrait = 1,
    kAutorotateToPortraitUpsideDown = 2,
    kAutorotateToLandscapeLeft = 4,
    kAutorotateToLandscapeRight = 8
};

ScreenOrientation       ConvertToUnityScreenOrientation(UIInterfaceOrientation hwOrient, EnabledOrientation* outAutorotOrient);
UIInterfaceOrientation  ConvertToIosScreenOrientation(ScreenOrientation orient);

bool                    UnityIsOrientationEnabled(EnabledOrientation orientation);
ScreenOrientation       UnityRequestedScreenOrientation();
void                    UnitySetScreenOrientation(ScreenOrientation orientation);

CGAffineTransform       TransformForOrientation( ScreenOrientation curOrient );
CGRect                  ContentRectForOrientation( ScreenOrientation orient );

void                    OrientView(UIView* view, ScreenOrientation target);


#endif // _TRAMPOLINE_IPHONE_ORIENTATIONSUPPORT_H_
