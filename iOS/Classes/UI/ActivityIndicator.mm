
#include "ActivityIndicator.h"
#include "iPhone_View.h"
#include "iPhone_OrientationSupport.h"

static ActivityIndicator*   _activityIndicator = nil;
static UIView*              _parent  = nil;


@implementation ActivityIndicator

- (void)layoutSubviews
{
    self.center = CGPointMake([_parent bounds].size.width/2, [_parent bounds].size.height/2);
}

+ (ActivityIndicator*)Instance
{
    return _activityIndicator;
}

@end

void ShowActivityIndicator(UIView* parent)
{
    if(_activityIndicator != nil)
        return;

    extern int UnityGetShowActivityIndicatorOnLoading();

    const int activityIndicatorStyle = UnityGetShowActivityIndicatorOnLoading();
    if( activityIndicatorStyle >= 0)
    {
        _activityIndicator = [[ActivityIndicator alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityIndicatorStyle];
        SetScreenFactorFromScreen(_activityIndicator);
    }

    if(_activityIndicator != nil)
    {
        _parent = parent;
        [_parent addSubview: _activityIndicator];
        [_activityIndicator startAnimating];
    }
}

void HideActivityIndicator()
{
    if( _activityIndicator )
    {
        [_activityIndicator stopAnimating];
        [_activityIndicator removeFromSuperview];
        [_activityIndicator release];
        _activityIndicator = nil;
    }
}



