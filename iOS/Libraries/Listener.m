//
//  Dispatcher.m
//  Unity-iPhone
//
//  Created by ludicvoice on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Listener.h"

@implementation Listener
@synthesize unityObject;
@synthesize unityMethod;
@synthesize unityMessage;
- (void)send
{
    NSLog(@"Sending to Object: %@ Method: %@ Message: %@", unityObject, unityMethod, unityMessage);
    UnitySendMessage([self.unityObject  cStringUsingEncoding:NSASCIIStringEncoding], 
                     [self.unityMethod  cStringUsingEncoding:NSASCIIStringEncoding], 
                     [self.unityMessage cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)receiveBangFromSource:(NSString *)source {
    NSLog(@"Received Bang from: %@", source);
    [self send];
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
    NSLog(@"Received Float: %f from: %@", received, source);
    self.unityMessage = [NSString stringWithFormat:@"%f", received];
    [self send];
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
    NSLog(@"Received Symbol: %@ from: %@", symbol, source);
    self.unityMessage = symbol;
    [self send];
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
    NSLog(@"Received List: %@ from: %@", list, source);
    [self send];
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
    NSLog(@"Received message: %@ withArguments: %@ from: %@", message, arguments, source);
    [self send];
}
@end
