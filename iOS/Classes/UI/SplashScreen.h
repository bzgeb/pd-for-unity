#ifndef _TRAMPOLINE_UI_SPLASHSCREEN_H_
#define _TRAMPOLINE_UI_SPLASHSCREEN_H_

#import <UIKit/UIKit.h>
#include "iPhone_Common.h"


@interface SplashScreen : UIImageView
{
    ScreenOrientation   splashImageOrient;
}
+ (SplashScreen*)Instance;
@end

@interface SplashScreenController : UIViewController {}
+ (SplashScreenController*)Instance;
@end

void    ShowSplashScreen(UIWindow* window);
void    HideSplashScreen();

#endif // _TRAMPOLINE_UI_SPLASHSCREEN_H_
