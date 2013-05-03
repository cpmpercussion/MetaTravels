//
//  MetatoneNetworkManager.m
//  Metatone
//
//  Created by Charles Martin on 10/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "MetatoneNetworkManager.h"
#define PORT 57120

@implementation MetatoneNetworkManager

-(MetatoneNetworkManager *) init
{
    self = [super init];
    self.connection = [[OSCConnection alloc] init];
    self.connection.delegate = self;
    self.connection.continuouslyReceivePackets = YES;
    
    self.deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    

    
    NSError *error;
    if (![self.connection bindToAddress:nil port:PORT error:&error])
    {
        NSLog(@"Could not bind UDP connection: %@", error);
        return nil;
    } else {
        NSLog(@"Connection Bound");

        // For now use local broadcast address:
        //self.remoteIPAddress = [MetatoneNetworkManager getLocalBroadcastAddress];
        self.remoteIPAddress = @"10.0.1.2";
        self.remotePort = PORT;
        [self.connection receivePacket];
        
        [self sendMessageOnline];
    }
    
    if (!self.remoteIPAddress) {
        return nil;
    } else {
        return self;
    }
}

# pragma mark Sending Methods

-(void)sendMessageWithAccelerationX:(double)x Y:(double)y Z:(double)z
{
    OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = @"/metatone/acceleration";
    [message addString:self.deviceID];
    [message addFloat:x];
    [message addFloat:y];
    [message addFloat:z];
    [self.connection sendPacket:message toHost:self.remoteIPAddress port:self.remotePort];
}

-(void)sendMessageWithTouch:(CGPoint)point Velocity:(CGFloat)vel
{
    OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = @"/metatone/touch";
    [message addString:self.deviceID];
    [message addFloat:point.x];
    [message addFloat:point.y];
    [message addFloat:vel];
    [self.connection sendPacket:message toHost:self.remoteIPAddress port:self.remotePort];
}

-(void)sendMesssageSwitch:(NSString *)name On:(BOOL)on
{
    OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = @"/metatone/switch";
    [message addString:self.deviceID];
    [message addString:name];
    [message addBool:on];
    [self.connection sendPacket:message toHost:self.remoteIPAddress port:self.remotePort];
}

-(void)sendMessageTouchEnded
{
    OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = @"/metatone/touch/ended";
    [message addString:self.deviceID];
    [self.connection sendPacket:message toHost:self.remoteIPAddress port:self.remotePort];
}

-(void)sendMessageOnline
{
    OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = @"/metatone/online";
    [message addString:self.deviceID];
    [self.connection sendPacket:message toHost:self.remoteIPAddress port:self.remotePort];
}

-(void)sendMessageOffline
{
    OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = @"/metatone/offline";
    [message addString:self.deviceID];
    [self.connection sendPacket:message toHost:self.remoteIPAddress port:self.remotePort];
}

#pragma mark Receiving Methods


-(void)oscConnection:(OSCConnection *)connection didReceivePacket:(OSCPacket *)packet fromHost:(NSString *)host port:(UInt16)port
{
    // Received an OSC message
}


#pragma mark IP Methods

// Get IP Address
+ (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

+ (NSString *)getLocalBroadcastAddress {
    NSArray *addressComponents = [[MetatoneNetworkManager getIPAddress] componentsSeparatedByString:@"."];
    NSString *address = nil;
    if ([addressComponents count] == 4)
    {
        address = @"";
        for (int i = 0; i<([addressComponents count] - 1); i++) {
            address = [address stringByAppendingString:addressComponents[i]];
            address = [address stringByAppendingString:@"."];
        }
        address = [address stringByAppendingString:@"255"];
    }
    return address;
}



@end
