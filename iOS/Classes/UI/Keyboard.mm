#include "Keyboard.h"
#include "iPhone_View.h"

#include <string>


NSString* const UIKeyboardWillChangeFrameNotification = @"UIKeyboardWillChangeFrameNotification";
NSString* const UIKeyboardDidChangeFrameNotification = @"UIKeyboardDidChangeFrameNotification";


static KeyboardDelegate*    _keyboard = nil;
static CGRect               _keyboardRect = CGRectMake(0,0,0,0);
static bool                 _shouldHideInput = false;


@implementation KeyboardDelegate

- (BOOL)textFieldShouldReturn:(UITextField*)textFieldObj
{
    [self hide];
    return YES;
}

- (void)textInputDone:(id)sender
{
    [self hide];
}

- (void)textInputCancel:(id)sender
{
    canceled = true;
    [self hide];
}

- (void)keyboardDidShow:(NSNotification*)notification;
{
    if (notification.userInfo == nil || inputView == nil)
        return;

    CGPoint center = [[notification.userInfo objectForKey:UIKeyboardCenterEndUserInfoKey] CGPointValue];
    CGRect  rect   = [[notification.userInfo objectForKey:UIKeyboardBoundsUserInfoKey] CGRectValue];

    float x = center.x - rect.size.width / 2;
    float y = center.y - rect.size.height / 2;
    [self positionInput:&rect x:x y:y];

    active = true;
}

- (void)keyboardWillHide:(NSNotification*)notification;
{
    _keyboardRect = CGRectMake(0,0,0,0);

    if (inputView == nil)
        return;

    toolbar.hidden = YES;
    if(textView)
        textView.hidden = YES;

    active = false;
}

- (void)keyboardDidChangeFrame:(NSNotification*)notification;
{
    active = true;

    CGRect srcRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect rect    = [UnityGetGLView() convertRect: srcRect fromView: nil];

    if( rect.origin.y >= [UnityGetGLView() bounds].size.height )
    {
        active  = false;
        toolbar.hidden = YES;

        if(textView)
            textView.hidden = YES;
    }
    else
    {
        [self positionInput:&rect x:rect.origin.x y:rect.origin.y];
    }
}

+ (void)Initialize
{
    NSAssert(_keyboard == nil, @"[KeyboardDelegate Initialize] called after creating keyboard");
    if(!_keyboard)
        _keyboard = [[KeyboardDelegate alloc] init];
}

+ (KeyboardDelegate*)Instance
{
    if(!_keyboard)
        _keyboard = [[KeyboardDelegate alloc] init];

    return _keyboard;
}

- (id)init
{
    NSAssert(_keyboard == nil, @"You can have only one instance of KeyboardDelegate");
    self = [super init];
    if(self)
    {
        textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 480, 480, 30)];
        [textView setDelegate: self];
        textView.font = [UIFont systemFontOfSize:18.0];
        textView.hidden = YES;

        textField = [[UITextField alloc] initWithFrame:CGRectMake(0,0,120,30)];
        [textField setDelegate: self];
        [textField setBorderStyle: UITextBorderStyleRoundedRect];
        textField.font = [UIFont systemFontOfSize:20.0];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;

        UIBarButtonItem* inputItem  = [[UIBarButtonItem alloc] initWithCustomView:textField];
        UIBarButtonItem* doneItem   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target:self action:@selector(textInputDone:)];
        UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target:self action:@selector(textInputCancel:)];

        viewToolbar = [[UIToolbar alloc] initWithFrame :CGRectMake(0,160,320,64)];
        viewToolbar.hidden = YES;
        viewToolbar.items = [[NSArray alloc] initWithObjects:doneItem, cancelItem, nil];

        fieldToolbar = [[UIToolbar alloc] initWithFrame :CGRectMake(0,160,320,64)];
        fieldToolbar.hidden = YES;
        fieldToolbar.items = [[NSArray alloc] initWithObjects:inputItem, doneItem, cancelItem, nil];

        [inputItem release];
        [doneItem release];
        [cancelItem release];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    }

    return self;
}

- (void)show:(KeyboardShowParam)param
{
    if(active)
        [self hide];

    initialText = param.text ? [[NSString alloc] initWithUTF8String: param.text] : @"";

    multiline = param.multiline;
    if(param.multiline)
    {
        [textView setText: initialText];
        [textView setKeyboardType: param.keyboardType];
        [textView setAutocorrectionType: param.autocorrectionType];
        [textView setSecureTextEntry: (BOOL)param.secure];
        [textView setKeyboardAppearance: param.appearance];
    }
    else
    {
        [textField setPlaceholder: [NSString stringWithUTF8String: param.placeholder]];
        [textField setText: initialText];
        [textField setKeyboardType: param.keyboardType];
        [textField setAutocorrectionType: param.autocorrectionType];
        [textField setSecureTextEntry: (BOOL)param.secure];
        [textField setKeyboardAppearance: param.appearance];
    }

    inputView = multiline ? textView : textField;
    toolbar   = multiline ? viewToolbar : fieldToolbar;

    [UnityGetGLView() addSubview:toolbar];
    if(multiline)
        [UnityGetGLView() addSubview:inputView];

    [inputView becomeFirstResponder];

    done        = false;
    canceled    = false;
    active      = true;

    // if we unhide everything now the input will be shown smaller then needed quickly (and resized later)
    // so unhide only when keyboard is shown
    [self setInputHidden:_shouldHideInput];
    textField.returnKeyType = inputHidden ? UIReturnKeyDone : UIReturnKeyDefault;
}

- (void)hide
{
    [self keyboardWillHide:nil];
    [inputView resignFirstResponder];

    if(multiline)
    {
        [inputView retain];
        [inputView removeFromSuperview];
    }

    [toolbar retain];
    [toolbar removeFromSuperview];

    done = true;
}

- (void)updateInputHidden
{
    textField.returnKeyType = inputHidden ? UIReturnKeyDone : UIReturnKeyDefault;
    toolbar.hidden = inputHidden ? YES : NO;
}

- (void)positionInput:(CGRect*)kbRect x:(float)x y:(float)y
{
    static const unsigned kInputBarSize = 48;

    if (multiline)
    {
        extern float UnityGetDPI();
        // use smaller area for iphones and bigger one for ipads
        int height = UnityGetDPI() > 300 ? 75 : 100;

        toolbar.frame   = CGRectMake(0, y - kInputBarSize, kbRect->size.width, kInputBarSize);
        inputView.frame = CGRectMake(0, y - kInputBarSize - height,kbRect->size.width, height);
        inputView.hidden = NO;
    }
    else
    {
        CGRect   statusFrame  = [UIApplication sharedApplication].statusBarFrame;
        unsigned statusHeight = statusFrame.size.height;

        toolbar.frame   = CGRectMake(0, y - kInputBarSize - statusHeight, kbRect->size.width, kInputBarSize);
        inputView.frame = CGRectMake(inputView.frame.origin.x, inputView.frame.origin.y,
                                     kbRect->size.width - 3*18 - 2*50, inputView.frame.size.height
                                    );
    }

    _keyboardRect = CGRectMake(x, y, kbRect->size.width, kbRect->size.height);
    [self updateInputHidden];
}

+ (void)StartReorientation
{
    if(_keyboard && _keyboard->active)
    {
        if( _keyboard->multiline )
            _keyboard->inputView.hidden = true;

        _keyboard->toolbar.hidden = true;
    }
}

+ (void)FinishReorientation
{
    if(_keyboard && _keyboard->active)
    {
        if( _keyboard->multiline )
            _keyboard->inputView.hidden = false;

        _keyboard->toolbar.hidden = false;

        [_keyboard->inputView resignFirstResponder];
        [_keyboard->inputView becomeFirstResponder];
    }
}

- (NSString*)getText
{
    if(canceled)    return initialText;
    else            return multiline ? [textView text] : [textField text];
}

- (void)setText:(NSString*)newText
{
    if(multiline)   [textView setText: newText];
    else            [textField setText: newText];
}

- (void)setInputHidden:(BOOL)hidden
{
    if(multiline)
        hidden = false;

    if(hidden)
    {
        switch(keyboardType)
        {
            case UIKeyboardTypeDefault:                 hidden = true;  break;
            case UIKeyboardTypeASCIICapable:            hidden = true;  break;
            case UIKeyboardTypeNumbersAndPunctuation:   hidden = true;  break;
            case UIKeyboardTypeURL:                     hidden = true;  break;
            case UIKeyboardTypeNumberPad:               hidden = false; break;
            case UIKeyboardTypePhonePad:                hidden = false; break;
            case UIKeyboardTypeNamePhonePad:            hidden = false; break;
            case UIKeyboardTypeEmailAddress:            hidden = true;  break;
            default:                                    hidden = false; break;
        }
    }

    inputHidden = hidden;
}

@end


//==============================================================================
//
//  Unity Interface:

void UnityKeyboard_Show(unsigned keyboardType, bool autocorrection, bool multiline, bool secure, bool alert, const char* text, const char* placeholder)
{
    static const UIKeyboardType keyboardTypes[] =
    {
        UIKeyboardTypeDefault,
        UIKeyboardTypeASCIICapable,
        UIKeyboardTypeNumbersAndPunctuation,
        UIKeyboardTypeURL,
        UIKeyboardTypeNumberPad,
        UIKeyboardTypePhonePad,
        UIKeyboardTypeNamePhonePad,
        UIKeyboardTypeEmailAddress,
    };

    static const UITextAutocorrectionType autocorrectionTypes[] =
    {
        UITextAutocorrectionTypeDefault,
        UITextAutocorrectionTypeNo,
    };

    static const UIKeyboardAppearance keyboardAppearances[] =
    {
        UIKeyboardAppearanceDefault,
        UIKeyboardAppearanceAlert,
    };

    KeyboardShowParam param =
    {
        text, placeholder,
        keyboardTypes[keyboardType],
        autocorrectionTypes[autocorrection ? 0 : 1],
        keyboardAppearances[alert ? 1 : 0],
        multiline, secure
    };

    [[KeyboardDelegate Instance] show:param];
}

void UnityKeyboard_Hide()
{
    // do not send hide if didnt create keyboard
    // TODO: probably assert?
    if(!_keyboard)
        return;

    [[KeyboardDelegate Instance] hide];
}

void UnityKeyboard_PositionTextInput(CGRect* keyboardRect, float x, float y)
{
    [[KeyboardDelegate Instance] positionInput:keyboardRect x:x y:y];
}

void UnityKeyboard_SetText(const char* text)
{
    [[KeyboardDelegate Instance] setText:[NSString stringWithUTF8String: text]];
}

void UnityKeyboard_GetText(std::string* text)
{
    *text = [[[KeyboardDelegate Instance] getText] UTF8String];
}

bool UnityKeyboard_IsActive()
{
    return _keyboard ? _keyboard->active : false;
}

bool UnityKeyboard_IsDone()
{
    return _keyboard ? _keyboard->done : false;
}

bool UnityKeyboard_WasCanceled()
{
    return _keyboard ? _keyboard->canceled : false;
}

void UnityKeyboard_SetInputHidden(bool hidden)
{
    _shouldHideInput = hidden;
    if(_keyboard)
    {
        [_keyboard setInputHidden:_shouldHideInput];
        [_keyboard updateInputHidden];
    }
}

bool UnityKeyboard_IsInputHidden()
{
    return _shouldHideInput;
}

void UnityKeyboard_GetRect(float* x, float* y, float* w, float* h)
{
    *x = _keyboardRect.origin.x;
    *y = _keyboardRect.origin.y;
    *w = _keyboardRect.size.width;
    *h = _keyboardRect.size.height;
}
