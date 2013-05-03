//
//  MetatoneTouchView.h
//  Metatone
//
//  Created by Charles Martin on 17/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MetatoneTouchView : UIView

@property (strong, nonatomic) NSMutableArray *touchCirclePoints;
@property (strong, nonatomic) NSMutableArray *noteCirclePoints;

@property (strong, nonatomic) CALayer *movingTouchCircleLayer;

-(void) drawTouchCircleAt:(CGPoint) point;
-(void) drawNoteCircleAt:(CGPoint) point;
-(void) drawMovingTouchCircleAt:(CGPoint) point;
-(void) hideMovingTouchCircle;


@end
