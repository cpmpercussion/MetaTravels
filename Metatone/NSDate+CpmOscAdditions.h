//
//  NSDate+CpmOscAdditions.h
//  CocoaOSC-TestApp
//
//  Created by Charles Martin on 28/03/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (CpmOscAdditions)
+ (NSDate *)ntpReferenceDate;
- (uint64_t)ntpTimestamp;
+ (NSDate *)dateWithNTPTimestamp:(uint64_t)timestamp;
@end
