//
//  NSArray+CpmOscAdditions.m
//  CocoaOSC-TestApp
//
//  Created by Charles Martin on 28/03/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "NSArray+CpmOscAdditions.h"

@implementation NSArray (CpmOscAdditions)
- (id)car
{
    if ([self count] > 0) return [self objectAtIndex:0];
    else return nil;
}

- (NSArray *)cdr
{
    if ([self count] > 1) return [self subarrayWithRange:NSMakeRange(1, [self count]-1)];
    else return nil;
}
@end
