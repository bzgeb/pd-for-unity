//
//  Dispatcher.h
//  Unity-iPhone
//
//  Created by ludicvoice on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PdBase.h"
#import "PdDispatcher.h"

@interface Listener : PdDispatcher <PdListener>

- (void)send;
@property (nonatomic, retain) NSString* unityObject;
@property (nonatomic, retain) NSString* unityMethod;
@property (nonatomic, retain) NSString* unityMessage;
@end
