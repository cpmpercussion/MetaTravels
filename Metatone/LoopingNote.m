//
//  LoopingNote.m
//  Metatone
//
//  Created by Charles Martin on 17/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "LoopingNote.h"
#import "MetatoneViewController.h"

#define LOOPS_LEFT 20
#define DEFAULT_TIME_JITTER 2
#define X_CENTER 512
#define Y_CENTER 394

@implementation LoopingNote

// Designated Initialiser.
- (LoopingNote *) initWithNotePoint:(CGPoint) notePoint LoopTime:(int) loopTime andDelegate:(id) delegate  {
    self = [super init];
    self.loopsLeft = LOOPS_LEFT - 10 + (arc4random() % 10);
    self.notePoint = notePoint;
    self.loopTime = loopTime /1000; //convert from Milliseconds to Seconds
    self.delegate = delegate;
    
    //NSLog([NSString stringWithFormat:@"Loop created with LoopsLeft:%d and LoopTime:%f seconds.", self.loopsLeft, self.loopTime]);
    
    // Schedule first timer.
    [self scheduleLoop];
    
    if ([delegate isKindOfClass:[MetatoneViewController class]]) {
        self.center = ((MetatoneViewController *)delegate).view.center;
    } else {
        self.center = CGPointMake(X_CENTER, Y_CENTER);
    }
    
    
    return self;
}




#define DELTA 1

// Delegated Method
-(void) playLoopingNote {
    
    // Tell Delegate to play the note
    if ([self.delegate respondsToSelector:@selector(loopingNotePlayed:)]) {
        
        [self.delegate loopingNotePlayed:self.notePoint];
        //NSLog(@"Play message sent to delegate");
    } else {
        //NSLog(@"Failed to send play message to deleagte.");
    }
    
    
    
    // Take one away from loops Left
    self.loopsLeft--;
    
    // Do some kind of notePoint Degradation...
    CGFloat delta = DELTA * ((float)arc4random()/0x100000000);
    CGFloat newX = delta * (self.notePoint.x) + (1 - delta) * self.center.x;
    CGFloat newY = delta * (self.notePoint.y) + (1 - delta) * self.center.y;
    //NSLog([NSString stringWithFormat:@"Delta: %f, Point: %f,%f", delta,newX,newY]);

    self.notePoint = CGPointMake(newX, newY);
    
    
    // Do some kind of loopTime Degradation...
    self.loopTime += ((float)arc4random()/0x100000000) * DEFAULT_TIME_JITTER;
    //NSLog([NSString stringWithFormat:@"Loop time: %f",self.loopTime]);
    
    
    // Schedule another note if required.
    if (self.loopsLeft) [self scheduleLoop];
}

-(void) scheduleLoop {
    [NSTimer scheduledTimerWithTimeInterval:self.loopTime target:self selector:@selector(playLoopingNote) userInfo:Nil repeats:NO];
    //NSLog([NSString stringWithFormat:@"Loop Scheduled, LoopsLeft:%d", self.loopsLeft]);
    
}


@end
