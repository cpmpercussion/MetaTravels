//
//  LoopingNote.h
//  Metatone
//
//  Created by Charles Martin on 17/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LoopingNoteDelegate <NSObject>
-(void) loopingNotePlayed: (CGPoint) notePoint;
@end


@interface LoopingNote : NSObject

@property (nonatomic) CGPoint notePoint;
@property (nonatomic) CGPoint center;
@property (nonatomic) int loopsLeft;
@property (nonatomic) float loopTime;
@property (weak,nonatomic) id<LoopingNoteDelegate> delegate;

- (LoopingNote *) initWithNotePoint:(CGPoint) notePoint LoopTime:(int) loopTime andDelegate:(id) delegate;

-(void) scheduleLoop;

@end

