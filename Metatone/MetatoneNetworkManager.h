//
//  MetatoneNetworkManager.h
//  Metatone
//
//  Created by Charles Martin on 10/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "CocoaOSC.h"
#import "RegexKitLite.h"
#import "NSString+CpmOscAdditions.h"
#import "NSArray+CpmOscAdditions.h"
#import "CocoaOSC/OSCConnection.h"

// IP Address method
#import <ifaddrs.h>
#import <arpa/inet.h>

@interface MetatoneNetworkManager : NSObject <OSCConnectionDelegate>

@property (strong, nonatomic) OSCConnection *connection;
@property (strong, nonatomic) NSString *remoteIPAddress;
@property (nonatomic) NSInteger remotePort;
@property (strong, nonatomic) NSString *deviceID;



+ (NSString *)getIPAddress;
+ (NSString *)getLocalBroadcastAddress;
- (void)sendMessageWithAccelerationX:(double) X Y:(double) Y Z:(double) Z;
- (void)sendMessageWithTouch:(CGPoint) point Velocity:(CGFloat) vel;
- (void)sendMessageTouchEnded;
-(void)sendMesssageSwitch:(NSString *)name On:(BOOL)on;

@end
