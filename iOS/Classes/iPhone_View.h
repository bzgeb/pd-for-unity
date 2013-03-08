#ifndef _TRAMPOLINE_IPHONE_VIEW_H_
#define _TRAMPOLINE_IPHONE_VIEW_H_

#import <UIKit/UIKit.h>
#include "iPhone_Common.h"


@interface EAGLView : UIView
{
    CGSize surfaceSize;
}
@end

@interface UnityViewController : UIViewController {}
@end

UIViewController*   UnityGetGLViewController();
UIView*             UnityGetGLView();
UIWindow*           UnityGetMainWindow();

ScreenOrientation   UnityCurrentOrientation();

void    CreateViewHierarchy();
void    ReleaseViewHierarchy();

void    OnUnityStartLoading();
void    OnUnityReady();

void    CheckOrientationRequest();
void    OrientTo(int requestedOrient);

float   ScreenScaleFactor();
void    SetScreenFactorFromScreen(UIView* view);

#endif // _TRAMPOLINE_IPHONE_VIEW_H_
