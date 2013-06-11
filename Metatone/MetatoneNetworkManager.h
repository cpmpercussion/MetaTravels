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

@protocol MetatoneNetworkManagerDelegate <NSObject>

-(void) searchingForLoggingServer;
-(void) loggingServerFoundWithAddress: (NSString *) address andPort: (int) port andHostname:(NSString *) hostname;
-(void) stoppedSearchingForLoggingServer;

@end

@interface MetatoneNetworkManager : NSObject <OSCConnectionDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate>

@property (strong, nonatomic) OSCConnection *connection;
@property (strong, nonatomic) NSString *remoteIPAddress;
@property (nonatomic) NSInteger remotePort;
@property (strong, nonatomic) NSString *remoteHostname;
@property (strong, nonatomic) NSString *deviceID;
@property (strong, nonatomic) NSNetService *metatoneNetService;
@property (strong, nonatomic) NSNetServiceBrowser *oscLoggerServiceBrowser;
@property (strong, nonatomic) NSNetService *oscLoggerService;

@property (weak,nonatomic) id<MetatoneNetworkManagerDelegate> delegate;


+ (NSString *)getIPAddress;
+ (NSString *)getLocalBroadcastAddress;

// Designated Initialiser
- (MetatoneNetworkManager *) initWithDelegate: (id<MetatoneNetworkManagerDelegate>) delegate;

- (void)sendMessageWithAccelerationX:(double) X Y:(double) Y Z:(double) Z;
- (void)sendMessageWithTouch:(CGPoint) point Velocity:(CGFloat) vel;
- (void)sendMessageTouchEnded;
-(void)sendMesssageSwitch:(NSString *)name On:(BOOL)on;

@end
