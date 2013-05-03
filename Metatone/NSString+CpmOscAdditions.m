//
//  NSString+CpmOscAdditions.m
//  CocoaOSC-TestApp
//
//  Created by Charles Martin on 28/03/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "NSString+CpmOscAdditions.h"

@implementation NSString (CpmOscAdditions)
- (NSData *)oscStringData
{
    NSMutableData *data = [[self dataUsingEncoding:NSASCIIStringEncoding] mutableCopy];
    
    // Add terminating NULL.
    [data setLength:[data length]+1];
    
    // Pad to multiple of 4 bytes if necessary.
    int rem = (int)([data length] % 4);
    if (rem != 0)
    {
        [data appendBytes:"\0\0\0" length:4-rem];
    }
    return data;
}
@end
