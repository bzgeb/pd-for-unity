#ifndef _TRAMPOLINE_UI_UNITYVIEWCONTROLLERBASE_H_
#define _TRAMPOLINE_UI_UNITYVIEWCONTROLLERBASE_H_

#import <UIKit/UIKit.h>

BOOL        ShouldAutorotateToInterfaceOrientation_DefaultImpl(id self_, SEL _cmd, UIInterfaceOrientation interfaceOrientation);
NSUInteger  SupportedInterfaceOrientations_DefaultImpl(id self_, SEL _cmd);
BOOL        ShouldAutorotate_DefaultImpl(id self_, SEL _cmd);

void        AddOrientationSupportDefaultImpl(Class targetClass);
void        AddShouldAutorotateToImplIfNeeded(Class targetClass, BOOL (*)(id, SEL, UIInterfaceOrientation));

#endif
