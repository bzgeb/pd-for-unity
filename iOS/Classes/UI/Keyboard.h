#ifndef _TRAMPOLINE_UI_KEYBOARD_H_
#define _TRAMPOLINE_UI_KEYBOARD_H_

#import <UIKit/UIKit.h>

struct
KeyboardShowParam
{
    const char* text;
    const char* placeholder;

    UIKeyboardType              keyboardType;
    UITextAutocorrectionType    autocorrectionType;
    UIKeyboardAppearance        appearance;

    bool multiline;
    bool secure;
};


@interface KeyboardDelegate : NSObject <UITextFieldDelegate, UITextViewDelegate>
{
@public
    UITextView*     textView;
    UIToolbar*      viewToolbar;

    UITextField*    textField;
    UIToolbar*      fieldToolbar;

    UIView*         inputView;
    UIToolbar*      toolbar;

    NSString*       initialText;

    UIKeyboardType  keyboardType;
    bool            inputHidden;

    bool multiline;
    bool active;
    bool done;
    bool canceled;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
- (void)textInputDone:(id)sender;
- (void)textInputCancel:(id)sender;
- (void)keyboardDidShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;

// on older devices initial keyboard creation might be slow, so it is good to init in on initial loading.
// on the ther hand, if you dont use keyboard (or use it rarely), you can avoid having all related stuff in memory:
//     keyboard will be created on demand anyway (in Instance method)
+ (void)Initialize;
+ (KeyboardDelegate*)Instance;

- (id)init;
- (void)show:(KeyboardShowParam)param;
- (void)hide;
- (void)positionInput:(CGRect*)keyboardRect x:(float)x y:(float)y;

+ (void)StartReorientation;
+ (void)FinishReorientation;

- (NSString*)getText;
- (void)setText:(NSString*)newText;

- (void)setInputHidden:(BOOL)hidden;
@end


#endif // _TRAMPOLINE_UI_KEYBOARD_H_
