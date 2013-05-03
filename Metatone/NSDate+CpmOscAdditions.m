//
//  NSDate+CpmOscAdditions.m
//  CocoaOSC-TestApp
//
//  Created by Charles Martin on 28/03/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "NSDate+CpmOscAdditions.h"

@implementation NSDate (CpmOscAdditions)

+ (NSDate *)ntpReferenceDate
{
    static NSDate *date = nil;
    if (!date)
    {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setYear:1900];
        [components setMonth:1];
        [components setDay:1];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        date = [[calendar dateFromComponents:components] copy];
    }
    return date;
}


- (uint64_t)ntpTimestamp
{
    NSTimeInterval interval = [self timeIntervalSinceReferenceDate];
    interval -= [[NSDate ntpReferenceDate] timeIntervalSinceReferenceDate];
    uint32_t seconds = (uint32_t)interval; //Floor
    uint32_t fractions = 0xffffffff * (interval - seconds);
    return ((uint64_t)seconds << 32) + fractions;
}

+ (NSDate *)dateWithNTPTimestamp:(uint64_t)timestamp
{
    uint32_t seconds = timestamp >> 32;
    uint32_t fractions = timestamp & 0xffffffff;
    NSTimeInterval interval = [[NSDate ntpReferenceDate] timeIntervalSinceReferenceDate];
    interval += (NSTimeInterval)seconds;
    interval += (NSTimeInterval)((double)fractions / 0xffffffff);
    return [NSDate dateWithTimeIntervalSinceReferenceDate:interval];
}

    
@end
