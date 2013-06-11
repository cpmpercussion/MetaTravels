//
//  MetatoneNetworkManager.m
//  Metatone
//
//  Created by Charles Martin on 10/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "MetatoneNetworkManager.h"
#define DEFAULT_PORT 57120
#define DEFAULT_ADDRESS @"10.0.1.2"
#define METATONE_SERVICE_TYPE @"_metatoneapp._udp"
#define OSCLOGGER_SERVICE_TYPE @"_osclogger._udp."

@implementation MetatoneNetworkManager

// Designated Initialiser
-(MetatoneNetworkManager *) initWithDelegate: (id<MetatoneNetworkManagerDelegate>) delegate {
    self = [super init];
    self.delegate = delegate;
    self.connection = [[OSCConnection alloc] init];
    self.connection.delegate = self;
    self.connection.continuouslyReceivePackets = YES;
    self.deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    
    NSError *error;
    if (![self.connection bindToAddress:nil port:DEFAULT_PORT error:&error])
    {
        NSLog(@"NETWORK MANAGER: Could not bind UDP connection: %@", error);
        return nil;
    } else {
        NSLog(@"NETWORK MANAGER: Setup Default OSC Connection.");
        self.remoteIPAddress = DEFAULT_ADDRESS;
        self.remotePort = DEFAULT_PORT;
        [self.connection receivePacket];
        [self sendMessageOnline];
    }
    
    // register with Bonjour
    self.metatoneNetService = [[NSNetService alloc]
                               initWithDomain:@""
                               type:METATONE_SERVICE_TYPE
                               name:[NSString stringWithFormat:@"%@", [UIDevice currentDevice].name]
                               port:DEFAULT_PORT];
    if (self.metatoneNetService != nil) {
        [self.metatoneNetService setDelegate: self];
        [self.metatoneNetService publishWithOptions:0];
        NSLog(@"NETWORK MANAGER: Metatone NetService Published.");
    }
    
    // try to find an OSC Logger to connect to
    NSLog(@"NETWORK MANAGER: Browsing for OSC Logger Services...");
    self.oscLoggerServiceBrowser  = [[NSNetServiceBrowser alloc] init];
    [self.oscLoggerServiceBrowser setDelegate:self];
    [self.oscLoggerServiceBrowser searchForServicesOfType:OSCLOGGER_SERVICE_TYPE
                                                 inDomain:@"local."];
    
    return self;
}

// Normal Initialiser --- works, but doesn't setup the initialiser fast enough to catch the NSNetServiceBrowser messages for the spinner animation, etc.
-(MetatoneNetworkManager *) init
{
    self = [super init];
    self.connection = [[OSCConnection alloc] init];
    self.connection.delegate = self;
    self.connection.continuouslyReceivePackets = YES;
    self.deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    
    NSError *error;
    if (![self.connection bindToAddress:nil port:DEFAULT_PORT error:&error])
    {
        NSLog(@"NETWORK MANAGER: Could not bind UDP connection: %@", error);
        return nil;
    } else {
        NSLog(@"NETWORK MANAGER: Setup Default OSC Connection.");
        self.remoteIPAddress = DEFAULT_ADDRESS;
        self.remotePort = DEFAULT_PORT;
        [self.connection receivePacket];
        [self sendMessageOnline];
    }
    
    // register with Bonjour
    self.metatoneNetService = [[NSNetService alloc]
                       initWithDomain:@""
                       type:METATONE_SERVICE_TYPE
                       name:[NSString stringWithFormat:@"%@", [UIDevice currentDevice].name]
                       port:DEFAULT_PORT];
    if (self.metatoneNetService != nil) {
        [self.metatoneNetService setDelegate: self];
        [self.metatoneNetService publishWithOptions:0];
        NSLog(@"NETWORK MANAGER: Metatone NetService Published.");
    }
    
    // try to find an OSC Logger to connect to
    NSLog(@"NETWORK MANAGER: Browsing for OSC Logger Services...");
    self.oscLoggerServiceBrowser  = [[NSNetServiceBrowser alloc] init];
    [self.oscLoggerServiceBrowser setDelegate:self];
    [self.oscLoggerServiceBrowser searchForServicesOfType:OSCLOGGER_SERVICE_TYPE
                                  inDomain:@"local."];
    
    return self;
    
//    if (!self.remoteIPAddress) {
//        return nil;
//    } else {
//        return self;
//    }
}

# pragma mark NetServiceBrowserDelegate Methods

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
    NSLog(@"NETWORK MANAGER: ERROR: Did not search for OSC Logger");
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSLog(@"NETWORK MANAGER: Found a NetService.");
    
    if ([[aNetService type] isEqualToString:OSCLOGGER_SERVICE_TYPE]) {
        NSLog(@"NETWORK MANAGER: Found an OSC Logger. Resolving.");
        self.oscLoggerService = aNetService;
        [self.oscLoggerService setDelegate:self];
        [self.oscLoggerService resolveWithTimeout:10.0];
        //[self.oscLoggerServiceBrowser stop];
        // need to do something about possibility of more than one OSC Logger.
    }
        
    if ([[aNetService type] isEqualToString:METATONE_SERVICE_TYPE]) {
        // do something else.
        NSLog(@"NETWORK MANAGER: Found a metatoneapp. Resolving.");
    }
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSString* firstAddress;
    int firstPort;
    
    for (NSData* data in [sender addresses]) {
        
        char addressBuffer[100];
        
        struct sockaddr_in* socketAddress = (struct sockaddr_in*) [data bytes];
        
        int sockFamily = socketAddress->sin_family;
        
        if (sockFamily == AF_INET || sockFamily == AF_INET6) {
            
            const char* addressStr = inet_ntop(sockFamily,
                                               &(socketAddress->sin_addr), addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sin_port);
            
            if (addressStr && port) {
                NSLog(@"NETWORK MANAGER: Resolved service of type %@ at %s:%d", [sender type], addressStr, port);
                firstAddress = [NSString stringWithFormat:@"%s",addressStr];
                firstPort = port;
                break;
            }
        }
        
    }
    
    if ([sender.type isEqualToString:OSCLOGGER_SERVICE_TYPE] && firstAddress && firstPort) {
        self.remoteHostname = sender.hostName;
        self.remoteIPAddress = firstAddress;
        self.remotePort = firstPort;
        
        [self.delegate loggingServerFoundWithAddress:self.remoteIPAddress andPort:self.remotePort andHostname:self.remoteHostname];
        [self sendMessageOnline];
        NSLog(@"NETWORK MANAGER: Resolved and Connected to an OSC Logger Service.");
    }
    
    if ([sender.type isEqualToString:METATONE_SERVICE_TYPE]) {
        NSLog(@"NETWORK MANAGER: Resolved a MetatoneApp Service.");
    }
    
}

-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
    NSLog(@"NETWORK MANAGER: NetServiceBrowser will search.");    
    [self.delegate searchingForLoggingServer];
}

-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
    NSLog(@"NETWORK MANAGER: NetServiceBrowser stopped searching.");
    [self.delegate stoppedSearchingForLoggingServer];
}

//// Tell Delegate to play the note
//if ([self.delegate respondsToSelector:@selector(loopingNotePlayed:)]) {
//    
//    [self.delegate loopingNotePlayed:self.notePoint];
//    //NSLog(@"Play message sent to delegate");
//} else {
//    //NSLog(@"Failed to send play message to delegate.");
//}


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
