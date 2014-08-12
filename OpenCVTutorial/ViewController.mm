//
//  ViewController.m
//  OpenCVTutorial
//
//  Created by Paul Sholtz on 12/14/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#import "AppDelegate.h"
#import "ViewController.h"
#import "ViewController+GameControls.h"

#import "VideoSource.h"
#import "PatternDetector.h"

#import "UIView+Animations.h"
#import "UIImage+OpenCV.h"
#import "ARView.h"

#pragma mark -
#pragma mark ViewController Class Extension
@interface ViewController () <VideoSourceDelegate>
{
    SystemSoundID m_soundExplosion;
    SystemSoundID m_soundShoot;
    SystemSoundID m_soundTracking;
    
    PatternDetector * m_detector;
    NSTimer * m_trackingTimer;
    NSTimer * m_sampleTimer;
    
    CameraCalibration m_calibration;
    CGFloat m_targetViewWidth;
    CGFloat m_targetViewHeight;
}

// Data Properties
@property (nonatomic, strong) VideoSource * videoSource;

// Transition Closures
@property (nonatomic, copy) void (^transitioningTrackerComplete)(void);
@property (nonatomic, copy) void (^transitioningTrackerCompleteResetScore)(void);

// Visualization Layer
@property (nonatomic, strong) ARView * arView;

@end

#pragma mark -
#pragma mark ViewController Implementation
@implementation ViewController

#pragma mark -
#pragma mark Accessors
- (void)setScore:(NSInteger)score {
    _score = score;
    [self.scoreValueLabel setText:[NSNumberFormatter localizedStringFromNumber:@(score) numberStyle:NSNumberFormatterDecimalStyle]];
}

#pragma mark -
#pragma mark Object Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure Video Source
    self.videoSource = [[VideoSource alloc] init];
    self.videoSource.delegate = self;
    [self.videoSource startWithDevicePosition:AVCaptureDevicePositionBack];
    
    // Activate Game Controls
    [self loadGameControls];
}

// Supporting iOS5
- (void)viewDidUnload
{
    self.backgroundImageView = nil;
    self.crosshairs = nil;
    
    self.tutorialPanel = nil;
    self.tutorialInnerPanel = nil;
    self.tutorialLabel = nil;
    self.tutorialDescLabel = nil;
    
    self.scorePanel = nil;
    self.scoreInnerPanel = nil;
    self.scoreValueLabel = nil;
    self.scoreHeaderLabel = nil;
    
    self.triggerPanel = nil;
    self.triggerLabel = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

#pragma mark -
#pragma mark IBAction Methods
- (IBAction)pressTrigger:(id)sender {
    NSInteger ring = [self selectRandomRing];
    switch ( ring ) {
        case 5: // Bullseye
            [self hitTargetWithPoints:kPOINTS_5];
            break;
        case 4:
            [self hitTargetWithPoints:kPOINTS_4];
            break;
        case 3:
            [self hitTargetWithPoints:kPOINTS_3];
            break;
        case 2:
            [self hitTargetWithPoints:kPOINTS_2];
            break;
        case 1: // Outermost Ring
            [self hitTargetWithPoints:kPOINTS_1];
            break;
        case 0: // Miss Target
            [self missTarget];
            break;
    }
}

- (IBAction)pressSample:(id)sender {
    if ( ![self isSamplePanelVisible] && !self.transitioningSample ) {
        self.transitioningSample = YES;
        
        // Clear the UI
        [self updateSample:nil];
        
        // Clear the timer
        if ( m_sampleTimer != nil ) {
            [m_sampleTimer invalidate];
            m_sampleTimer = nil;
        }
        
        // Start the timer
        m_sampleTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0f/20.0f)
                                                         target:self
                                                       selector:@selector(updateSample:)
                                                       userInfo:nil
                                                        repeats:YES];
        
        __weak typeof(self) _weakSelf = self;
        [self.samplePanel popIn:^{
            _weakSelf.transitioningSample = NO;
        }];
    }
}

- (IBAction)pressSampleClose:(id)sender {
    if ( [self isSamplePanelVisible] && !self.transitioningSample ) {
        self.transitioningSample = YES;
        
        // Terminate the timer
        [m_sampleTimer invalidate];
        m_sampleTimer = nil;
        
        __weak typeof(self) _weakSelf = self;
        [self.samplePanel popOut:^{
            _weakSelf.transitioningSample = NO;
        }];
    }
}

#pragma mark -
#pragma mark View State Methods
- (BOOL)isTutorialPanelVisible {
    return (self.tutorialPanel.alpha == 1.0f);
}

- (BOOL)isSamplePanelVisible {
    return (self.samplePanel.alpha == 1.0f);
}

#pragma mark -
#pragma mark Audio Support
- (void)loadSounds {
    CFURLRef soundURL1 = (__bridge CFURLRef)[NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"powerup" ofType:@"caf"]];
    CFURLRef soundURL2 = (__bridge CFURLRef)[NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"laser" ofType:@"caf"]];
    CFURLRef soundURL3 = (__bridge CFURLRef)[NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"explosion" ofType:@"caf"]];
    
    AudioServicesCreateSystemSoundID(soundURL1, &m_soundTracking);
    AudioServicesCreateSystemSoundID(soundURL2, &m_soundShoot);
    AudioServicesCreateSystemSoundID(soundURL3, &m_soundExplosion);
}

#pragma mark -
#pragma mark Game Play
- (void)hitTargetWithPoints:(NSInteger)points {
    // (1) Play the hit sound
    AudioServicesPlaySystemSound(m_soundExplosion);
    
    // (2) Animate the floating scores
    [self showFloatingScore:points];
    
    // (3) Update the score
    [self setScore:(self.score + points)];
}

- (void)missTarget {
    // (1) Play the miss sound
    AudioServicesPlaySystemSound(m_soundShoot);
}

#pragma mark -
#pragma mark Tracking Methods
- (void)updateTracking:(NSTimer*)timer {
    // TODO: Add code here
}

- (void)updateSample:(NSTimer*)timer {
    // TODO: Add code here
}

- (void)togglePanels {
    // TODO: Add code here
}

#pragma mark -
#pragma mark VideoSource Delegate
- (void)frameReady:(VideoFrame)frame {
    __weak typeof(self) _weakSelf = self;
    dispatch_sync( dispatch_get_main_queue(), ^{
        // Construct CGContextRef from VideoFrame
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(frame.data,
                                                        frame.width,
                                                        frame.height,
                                                        8,
                                                        frame.stride,
                                                        colorSpace,
                                                        kCGBitmapByteOrder32Little |
                                                        kCGImageAlphaPremultipliedFirst);
        
        // Construct CGImageRef from CGContextRef
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        // Construct UIImage from CGImageRef
        UIImage * image = [UIImage imageWithCGImage:newImage];
        CGImageRelease(newImage);
        [[_weakSelf backgroundImageView] setImage:image];
    });
}

@end
