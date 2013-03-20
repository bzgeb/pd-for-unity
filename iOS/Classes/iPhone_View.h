#ifndef _TRAMPOLINE_IPHONE_VIEW_H_
#define _TRAMPOLINE_IPHONE_VIEW_H_

#import <UIKit/UIKit.h>
#include "iPhone_Common.h"
#include "Unity/GlesHelper.h"


@interface MainGLView : GLView {}
@end

@interface UnityViewController : UIViewController {}
@end

UIViewController*   UnityGetGLViewController();
UIView*             UnityGetGLView();
UIWindow*           UnityGetMainWindow();

ScreenOrientation   UnityCurrentOrientation();

void    CreateViewHierarchy();
void    OnUnityInited();
void    OnUnityReady();
void    ReleaseViewHierarchy();

void    CheckOrientationRequest();
void    OrientTo(int requestedOrient);

float   ScreenScaleFactor();
void    SetScreenFactorFromScreen(UIView* view);

#endif // _TRAMPOLINE_IPHONE_VIEW_H_
