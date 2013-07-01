//
//  MetatoneViewController.m
//  Metatone
//
//  Created by Charles Martin on 7/04/13.
//  Copyright (c) 2013 Charles Martin. All rights reserved.
//

#import "MetatoneViewController.h"
#import "MetatoneTouchView.h"

#define TAP_MODE_FIELDS 0
#define TAP_MODE_MELODY 1
#define TAP_MODE_BOTH 2
#define LOOP_TIME 5000


@interface MetatoneViewController () {
    NSOperationQueue *queue;
}

@property (strong,nonatomic) PdAudioController *audioController;
@property (strong,nonatomic) MetatoneNetworkManager *networkManager;
@property (strong, nonatomic) CMMotionManager* motionManager;
@property (nonatomic) Boolean oscLogging;
@property (nonatomic) Boolean accelLogging;

@property (nonatomic) Boolean tapLooping;
@property (weak, nonatomic) IBOutlet UILabel *oscLoggingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *oscLoggingSpinner;
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGestureRecognizer;
@property (strong, nonatomic) NSMutableArray *loopedNotes;
@property (weak, nonatomic) IBOutlet MetatoneTouchView *touchView;
@property (nonatomic) int tapMode;
@end

@implementation MetatoneViewController

- (PdAudioController *) audioController
{
    if (!_audioController) _audioController = [[PdAudioController alloc] init];
    return _audioController;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Randomise Sounds each time the app is back in focus
    [PdBase sendBangToReceiver:@"randomiseSounds"];
    
    // Setup Networking
    //[[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"appeared.");
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Setup Pd
    //[self.audioController configurePlaybackWithSampleRate:22050 numberChannels:2 inputEnabled:NO mixingEnabled:NO];
    if([self.audioController configurePlaybackWithSampleRate:44100 numberChannels:2 inputEnabled:YES mixingEnabled:YES] != PdAudioOK) {
        NSLog(@"failed to initialise audioController");
    } else {
        NSLog(@"audioController initialised.");
    }
    
    [PdBase openFile:@"metatone_sounds.pd" path:[[NSBundle mainBundle] bundlePath]];
    [self.audioController setActive: YES];
    [self.audioController print];
    [PdBase setDelegate:self];
    [PdBase sendBangToReceiver:@"randomiseSounds"];
    
    
    // Setup Logging
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OSCLogging"]) {
        [self setupOscLogging];
        NSLog(@"Setup Logging.");
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AccelerationLogging"]) {
            self.accelLogging = YES;
        }
    } else {
        [self.oscLoggingLabel setText:@""];
        NSLog(@"Stopped Logging.");
    }
    
    
    // Setup Accelerometer
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startDeviceMotionUpdates];
    
    if (self.accelLogging) {
        self.motionManager.accelerometerUpdateInterval = 1.0/100.0;
        if (self.motionManager.accelerometerAvailable) {
            NSLog(@"Accelerometer Available.");
            queue = [NSOperationQueue currentQueue];
            [self.motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                CMAcceleration acceleration = accelerometerData.acceleration;
                if (self.oscLogging) [self.networkManager sendMessageWithAccelerationX:acceleration.x Y:acceleration.y Z:acceleration.z];
            }];
        }
    }
    
    // Looping Test
    self.tapLooping = YES;
    self.tapMode = 0;
}

#pragma mark - Note Methods

-(void)triggerTappedNote:(CGPoint)tapPoint {
    // Send to Pd
    if (self.tapMode == TAP_MODE_FIELDS || self.tapMode == TAP_MODE_FIELDS) {
        [PdBase sendBangToReceiver:@"touch" ]; // makes a small sound
        [PdBase sendFloat:[self calculateDistanceFromCenter:tapPoint]/600 toReceiver:@"tapdistance" ];
    }
    
    if (self.tapMode == TAP_MODE_MELODY || self.tapMode == TAP_MODE_BOTH) {
        [self sendMidiNoteFromPoint:tapPoint withVelocity:40];
    }
}

-(void)scheduleRecurringTappedNote:(CGPoint)tapPoint {
    // max 100 notes in the loopedNotes array.
    if ([self.loopedNotes count] > 100) [self.loopedNotes removeObjectAtIndex:0];
    
    // add the looped note.
    [self.loopedNotes addObject:[[LoopingNote alloc] initWithNotePoint:tapPoint LoopTime:LOOP_TIME andDelegate:self]];
    //NSLog(@"Added a Looping Note");
}

-(CGFloat)calculateDistanceFromCenter:(CGPoint)touchPoint {
    CGFloat xDist = (touchPoint.x - self.view.center.y);
    CGFloat yDist = (touchPoint.y - self.view.center.x);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

-(void) loopingNotePlayed:(CGPoint)notePoint {
    if (self.tapLooping) [self triggerTappedNote:notePoint];
    if (self.tapLooping) [self.touchView drawNoteCircleAt:notePoint];
}



#pragma mark - Touch

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"Tap.");
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    CGFloat distance = [self calculateDistanceFromCenter:touchPoint] /600;
    
    // Measure Acceleration
    CMDeviceMotion *motion = self.motionManager.deviceMotion;
    int velocity = (int) (ABS(motion.userAcceleration.z * 3000) + 5) % 128;
    NSLog([NSString stringWithFormat:@"Z Accel: %d", velocity]);
    
    
    
    // Send to Pd - receiver
    if (self.tapMode == TAP_MODE_FIELDS || self.tapMode == TAP_MODE_FIELDS) {
        [PdBase sendBangToReceiver:@"touch" ]; // makes a small sound
        [PdBase sendFloat:distance toReceiver:@"tapdistance" ];
    }
    
    // Send to Pd as a midi note.
    if (self.tapMode == TAP_MODE_MELODY || self.tapMode == TAP_MODE_BOTH) {
        [self sendMidiNoteFromPoint:touchPoint withVelocity:velocity];
    }
    
    // Logging, Looping and Display.
    if (self.tapLooping) [self scheduleRecurringTappedNote:touchPoint]; // setup looping note
    if (self.oscLogging) [self.networkManager sendMessageWithTouch:touchPoint Velocity:0.0]; // osc logging
    [self.touchView drawTouchCircleAt:touchPoint]; // draw in the view
}



-(void)sendMidiNoteFromPoint:(CGPoint) point withVelocity:(int) vel
{
    CGFloat distance = [self calculateDistanceFromCenter:point]/600;
    // Testing sending a midi message as well.
    int velocity = ((int) 25 + 100 * (point.y / 800));
    velocity = (int) (velocity * 0.2) + (vel * 0.8); // include the tap acceleration measurement.
    
    [PdBase sendNoteOn:1 pitch:((int) (30 + 60*distance)) velocity:velocity];
    
}


-(void)touchesMoved:(NSSet *) touches withEvent:(UIEvent *)event
{
    // a moving touch.
    // take distance from center
    // take delta from previous location (proportional to velocity)
    UITouch *touch = [touches anyObject];
    CGFloat xVelocity = [touch locationInView:self.view].x - [touch previousLocationInView:self.view].x;
    CGFloat yVelocity = [touch locationInView:self.view].y - [touch previousLocationInView:self.view].y;
    CGFloat velocity = sqrt((xVelocity * xVelocity) + (yVelocity * yVelocity));
    
    //NSLog([NSString stringWithFormat:@"Velocity: %f", velocity]);
    if (self.oscLogging) [self.networkManager sendMessageWithTouch:[touch locationInView:self.view] Velocity:velocity];
    
    [self.touchView drawMovingTouchCircleAt:[touch locationInView:self.view]];

}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.oscLogging) [self.networkManager sendMessageTouchEnded];
    [self.touchView hideMovingTouchCircle];
}

#pragma mark - UI

// Cluster Auto Play Switch
- (IBAction)clustersOn:(UISwitch *)sender {
    if (self.oscLogging) [self.networkManager sendMesssageSwitch:@"clustersOn" On:sender.on];
    if (sender.on)
    {
        [PdBase sendFloat:1 toReceiver:@"autoBowl"];
    } else {
        [PdBase sendFloat:0 toReceiver:@"autoBowl"];
    }
}

// Cymbal Auto Play Switch
- (IBAction)cymbalsOn:(UISwitch *)sender {
    if (self.oscLogging) [self.networkManager sendMesssageSwitch:@"cymbalsOn" On:sender.on];
    if (sender.on)
    {
        [PdBase sendFloat:1 toReceiver:@"autoCymbal"];
    } else {
        [PdBase sendFloat:0 toReceiver:@"autoCymbal"];
    }
}

// Field Recording auto play Switch
- (IBAction)fieldsOn:(UISwitch *)sender {
    if (self.oscLogging) [self.networkManager sendMesssageSwitch:@"fieldsOn" On:sender.on];
    if (sender.on)
    {
        [PdBase sendFloat:1 toReceiver:@"autoField"];
    } else {
        [PdBase sendFloat:0 toReceiver:@"autoField"];
    }
}


// Loop Control Button
- (IBAction)loopingOn:(UISwitch *)sender {
    if (self.oscLogging) [self.networkManager sendMesssageSwitch:@"loopingOn" On:sender.on];
    self.tapLooping = sender.on;
    if (!sender.on) {
        [self.loopedNotes removeAllObjects];
    }
}

// Reset Sounds Button
- (IBAction)reset:(id)sender {
    if (self.oscLogging) [self.networkManager sendMesssageSwitch:@"resetButton" On:YES];
    [PdBase sendBangToReceiver:@"randomiseSounds"];
    self.tapMode = (self.tapMode + 1) % 3;
}

- (IBAction)panGestureRecognized:(UIPanGestureRecognizer *)sender {
    CGFloat xVelocity = [sender velocityInView:self.view].x;
    CGFloat yVelocity = [sender velocityInView:self.view].y;
    CGFloat velocity = sqrt((xVelocity * xVelocity) + (yVelocity * yVelocity));
    
    //NSLog([NSString stringWithFormat:@"Vel: %f",velocity]);
    
    if ([sender state] == UIGestureRecognizerStateBegan) {
        // send pan began message
        [PdBase sendFloat:velocity toReceiver:@"panstarted"];
        //if (self.oscLogging) [self.networkManager sendMessageWithTouch:[sender locationInView:self.view] Velocity:velocity];
        
    } else if ([sender state] == UIGestureRecognizerStateChanged) {
        // send normal pan changed message
        [PdBase sendFloat:velocity toReceiver:@"touchvelocity" ];
        
        //if (self.oscLogging) [self.networkManager sendMessageWithTouch:[sender locationInView:self.view] Velocity:velocity];
        
    } else if (([sender state] == UIGestureRecognizerStateEnded) || ([sender state] == UIGestureRecognizerStateCancelled)) {
        [PdBase sendBangToReceiver:@"touchended" ];
        //if (self.oscLogging) [self.networkManager sendMessageTouchEnded];
    }
}

#pragma mark - OSC LOGGING

- (void)setupOscLogging
{
    // Search network for metatoneLogging sessions
    // Initialise Network
    self.networkManager = [[MetatoneNetworkManager alloc] initWithDelegate:self];
    
    if (!self.networkManager) {
        self.oscLogging = NO;
        [self.oscLoggingLabel setText:@"OSC Logging: Not Connected"];
        NSLog(@"OSC Logging: Not Connected");
    } else {
        self.oscLogging = YES;
    }
}

- (void) searchingForLoggingServer {
    // Spin the spinner - write "Searching for Logging Server" in the field
    [self.oscLoggingSpinner startAnimating];
    [self.oscLoggingLabel setText:@"Searching for Logging Server..."];
}

-(void) loggingServerFoundWithAddress:(NSString *)address andPort:(int)port andHostname:(NSString *)hostname {
    // Stop the spinner - update info in the field
    [self.oscLoggingSpinner stopAnimating];
    [self.oscLoggingLabel setText:[NSString stringWithFormat:@"Logging to %@\n %@:%d", hostname, address,port]];
}

-(void) stoppedSearchingForLoggingServer {
    // stop the spinner - write "Logging Server Not Found" in the field.
    [self.oscLoggingSpinner stopAnimating];
    [self.oscLoggingLabel setText: @"Logging Server Not Found!"];
}

@end
