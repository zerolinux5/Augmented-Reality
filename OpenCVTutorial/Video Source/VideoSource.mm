//
//  VideoSource.m
//  OpenCVTutorial
//
//  Created by Paul Sholtz on 12/14/13.
//  Copyright (c) 2013 Razeware LLC. All rights reserved.
//

#import "VideoSource.h"

#pragma mark -
#pragma mark VideoSource Class Extension
@interface VideoSource ()

@end

#pragma mark -
#pragma mark VideoSource Implementation
@implementation VideoSource

#pragma mark -
#pragma mark Object Lifecycle
- (id)init {
    self = [super init];
    if ( self ) {
        AVCaptureSession * captureSession = [[AVCaptureSession alloc] init];
        if ( [captureSession canSetSessionPreset:AVCaptureSessionPreset640x480] ) {
            [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
            NSLog(@"Capturing video at 640x480");
        } else {
            NSLog(@"Could not configure AVCaptureSession video input");
        }
        _captureSession = captureSession;
    }
    return self;
}

- (void)dealloc {
    [_captureSession stopRunning];
}

#pragma mark -
#pragma mark Public Interface
- (BOOL)startWithDevicePosition:(AVCaptureDevicePosition)devicePosition {
    // TODO: Add code here
    return FALSE;
}

#pragma mark -
#pragma mark Helper Methods
- (AVCaptureDevice*)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice * device in devices ) {
        if ( [device position] == position ) {
            return device;
        }
    }
    return nil;
}

- (void)addVideoDataOutput {
    // TODO: Add code here
}

@end
