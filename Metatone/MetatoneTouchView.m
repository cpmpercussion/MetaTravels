//
//  MetatoneTouchView.m
//  Metatone
//
//  Created by Charles Martin on 17/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "MetatoneTouchView.h"
#import <QuartzCore/QuartzCore.h>

@interface MetatoneTouchView()

@property (strong, nonatomic) UIImage *lastFrame;
@property (strong, nonatomic) CALayer *animationLayer;

@end

@implementation MetatoneTouchView

- (NSMutableArray *) touchCirclePoints {
    if (!_touchCirclePoints) _touchCirclePoints = [[NSMutableArray alloc] init];
    return _touchCirclePoints;
}

- (NSMutableArray *)noteCirclePoints {
    if (!_noteCirclePoints) _noteCirclePoints = [[NSMutableArray alloc] init];
    return _noteCirclePoints;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSLog(@"View initialised");
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        
        self.movingTouchCircleLayer = [self makeCircleLayerWithColour:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.8]];
        [self.layer addSublayer:self.movingTouchCircleLayer];
        self.movingTouchCircleLayer.hidden = YES;
    }
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSLog(@"Init with Coderd");
        self.movingTouchCircleLayer = [self makeCircleLayerWithColour:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.8]];
        [self.layer addSublayer:self.movingTouchCircleLayer];
        self.movingTouchCircleLayer.hidden = YES;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
}
*/


-(void) drawTouchCircleAt:(CGPoint) point {
    CALayer *layer = [self makeCircleLayerWithColour:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.8]];
    [self.touchCirclePoints addObject:layer];
    
    [CATransaction setAnimationDuration:0.0];
    layer.position = point;
    layer.hidden = NO;
    [CATransaction setCompletionBlock:^{
        [CATransaction setAnimationDuration:2.0];
        layer.hidden = YES;
        [CATransaction setCompletionBlock:^{
            [self.touchCirclePoints removeObject:layer];
        }];
    }];    
}


-(void) drawNoteCircleAt:(CGPoint) point {
    CALayer *layer = [self makeCircleLayerWithColour:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.8]];
    
    [self.noteCirclePoints addObject:layer];
    
    [CATransaction setAnimationDuration:0.0];
    layer.position = point;
    layer.hidden = NO;
    [CATransaction setCompletionBlock:^{
        [CATransaction setAnimationDuration:2.0];
        layer.hidden = YES;
        [CATransaction setCompletionBlock:^{
            [self.noteCirclePoints removeObject:layer];
        }];
    }];
    
}


-(CALayer *) makeCircleLayerWithColour:(UIColor *) colour {
    CALayer *layer = [[CALayer alloc] init];
    
    layer.backgroundColor = colour.CGColor;
    layer.shadowOffset = CGSizeMake(0, 3);
    layer.shadowRadius = 5.0;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.8;
    layer.frame = CGRectMake(0, 0, 30, 30);
    layer.cornerRadius = 15.0;
    [self.layer addSublayer:layer];
    layer.hidden = YES;
    
    return layer;
}

-(void) drawMovingTouchCircleAt:(CGPoint)point {
    [CATransaction setAnimationDuration:0.0];
    self.movingTouchCircleLayer.position = point;
    self.movingTouchCircleLayer.hidden = NO;
}

-(void) hideMovingTouchCircle {
    [CATransaction setAnimationDuration:1.0];
    self.movingTouchCircleLayer.hidden = YES;
}


//-(CALayer *) movingTouchCircleLayer {
//    if (!_movingTouchCircleLayer) {
//        _movingTouchCircleLayer = [self makeCircleLayerWithColour:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.8]];
//    }
//    [self.layer addSublayer:_movingTouchCircleLayer];
//    _movingTouchCircleLayer.hidden = YES;
//    return _movingTouchCircleLayer;
//}



@end
