//
//  ZVideoRecorderViewController.m
//  VideoReviewsExample
//
//  Created by Jai Govindani on 2/23/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#define VideoRecordingConfigurationUserDefaultsKey  @"videoRecordingConfiguration"

#import "ZVideoRecorderViewController.h"
#import "PBJVision.h"
#import "PBJVisionUtilities.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <GLKit/GLKit.h>

#import <PBJVideoPlayer/PBJVideoPlayerController.h>
#import "RNTimer.h"
#import <ZProgressView/ZProgressView.h>
#import <ZProgressView/ZProgressViewStop.h>
#import "R20PopoverView.h"
#import "R20PopoverView+StaticShowMethods.h"
#import "PBJFocusView.h"

#define MAX_VIDEO_DURATION  5.0f
#define TIMER_TICK          0.1f

@interface ZVideoRecorderViewController () <UIGestureRecognizerDelegate,
PBJVisionDelegate, PBJVideoPlayerControllerDelegate, UIAlertViewDelegate>
{
    ALAssetsLibrary *_assetsLibrary;
    AVCaptureVideoPreviewLayer *_previewLayer;
    
    //Gesture recognizers
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    UITapGestureRecognizer *_tapGestureRecognizer;
    GLKViewController *_effectsViewController;
    
    UIView *_gestureView;
    PBJFocusView *_focusView;
    BOOL _recording;
    BOOL _activelyRecording;
    
    BOOL _isFocusing;
    BOOL _isAdjustingExposure;
    NSDate *_lastFocusTime;
    NSDate *_lastExposureTime;
    BOOL _focusQueued;
    CGPoint _queuedFocusPoint;
    
    __block NSDictionary *_currentVideo;
    
    NSTimer *_recordingTimer;
    CGFloat _recordingTimeRemaining;
    
    PBJVideoPlayerController *_videoPlayerController;
    UIAlertView *_discardAlertView;
    UIAlertView *_cancelRecordingAlertView;
    RNTimer *_gcdRecordingTimer;
    
    UIColor *_controlViewRecordingModeBackgroundColor;
    UIColor *_controlViewPlaybackModeBackgroundColor;
}

@end

@implementation ZVideoRecorderViewController

+ (instancetype)videoRecorder {
    return [[ZVideoRecorderViewController alloc] initWithNibName:@"ZVideoRecorderViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    
    //Set custom bitrate config (if any)
    NSDictionary *config = [[NSUserDefaults standardUserDefaults] dictionaryForKey:VideoRecordingConfigurationUserDefaultsKey];
    if (config) {
        
        NSNumber *videoBitRate = [config objectForKey:@"videoBitRate"];
        NSNumber *audioBitRate = [config objectForKey:@"audioBitRate"];
        NSString *AVCaptureSessionPreset = [config objectForKey:@"AVCaptureSessionPreset"];
        
        if ([videoBitRate isKindOfClass:[NSNumber class]]) {
            [PBJVision sharedInstance].videoBitRate = [videoBitRate floatValue] * 8;
        }
        
        if ([audioBitRate isKindOfClass:[NSNumber class]]) {
            [PBJVision sharedInstance].audioBitRate = [audioBitRate floatValue];
        }
        
        if ([AVCaptureSessionPreset isKindOfClass:[NSString class]]) {
            [PBJVision sharedInstance].captureSessionPreset = AVCaptureSessionPreset;
        }
    }
    
    //Set up the preview view
    _previewLayer = [[PBJVision sharedInstance] previewLayer];
    _previewLayer.frame = _previewView.bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewView.layer addSublayer:_previewLayer];
        
    //Tap to record gesture recognizer
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestureRecognizer:)];
    _longPressGestureRecognizer.delegate = self;
    _longPressGestureRecognizer.minimumPressDuration = 0.05f;
    _longPressGestureRecognizer.allowableMovement = 10.0f;
    
    //Onion Skin - disabled
    /*
     _effectsViewController = [[GLKViewController alloc] init];
     _effectsViewController.preferredFramesPerSecond = 60;
     
     GLKView *view = (GLKView*)_effectsViewController.view;
     CGRect viewFrame = self.previewView.bounds;
     
     view.frame = viewFrame;
     view.context = [[PBJVision sharedInstance] context];
     view.contentScaleFactor = [[UIScreen mainScreen] scale];
     view.alpha = 0.5f;
     view.hidden = YES;
     [[PBJVision sharedInstance] setPresentationFrame:_previewView.frame];
     [_previewView addSubview:_effectsViewController.view];
     */
    
    //Tap to focus - Disabled
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureRecognizer:)];
    _tapGestureRecognizer.delegate = self;
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    _tapGestureRecognizer.enabled = YES;
    [_previewView addGestureRecognizer:_tapGestureRecognizer];
    
    _focusView = [[PBJFocusView alloc] initWithFrame:CGRectZero];
    
    [[PBJVision sharedInstance] setFocusMode:PBJFocusModeAutoFocus];

    _longPressGestureRecognizer.cancelsTouchesInView = NO;
    [self.shutterButton addGestureRecognizer:_longPressGestureRecognizer];
    
//    [self.shutterButton addTarget:self action:@selector(handleShutterButtonPressed:) forControlEvents:UIControlEventTouchDown];
//    [self.shutterButton addTarget:self action:@selector(handleShutterButtonReleased:) forControlEvents:UIControlEventTouchUpInside];
//    [self.shutterButton addTarget:self action:@selector(handleShutterButtonReleased:) forControlEvents:UIControlEventTouchDragExit];
//    [self.shutterButton addTarget:self action:@selector(handleShutterButtonReleased:) forControlEvents:UIControlEventTouchUpOutside];

    [self.recordingProgressView setProgressBarColor:[UIColor colorWithRed:230/255.0 green:126/255.0 blue:34/255.0 alpha:1.0f]];
    
    if (self.minVideoDuration) {
        [self.recordingProgressView addStopAtPosition:(1 - ((self.maxVideoDuration - self.minVideoDuration) / self.maxVideoDuration))];
    }
    
    self.flipCameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.finishRecordingButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayerPlaybackEnded)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    
    UIColor *blueControlViewBackgroundColor = [UIColor colorWithRed:52/255.0 green:152/255.0 blue:219/255.0 alpha:1.0f];
    
    [self setControlViewBackgroundColor:blueControlViewBackgroundColor forMode:kVideoRecorderModeRecording];
    [self setControlViewBackgroundColor:[UIColor whiteColor] forMode:kVideoRecorderModePlayback];
    
    self.view.backgroundColor = blueControlViewBackgroundColor;
    self.recordingProgressView.backgroundColor = [UIColor blackColor];
    
    [self.finishRecordingButton setTitle:NSLocalizedString(@"NEXT", @"Recording - button for finishing") forState:UIControlStateNormal];
    [self.finishRecordingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.finishRecordingButton.titleLabel.font = [UIFont systemFontOfSize:18];
    self.finishRecordingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotate:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)didRotate:(NSNotification*)notification {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        {
            [UIView animateWithDuration:0.2 animations:^{
                self.flipCameraButton.transform = CGAffineTransformMakeRotation(0);
            }];
        }
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            [UIView animateWithDuration:0.2 animations:^{
                self.flipCameraButton.transform = CGAffineTransformMakeRotation(M_PI);
            }];
        }
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
        {
            [UIView animateWithDuration:0.2 animations:^{
                self.flipCameraButton.transform = CGAffineTransformMakeRotation(-M_PI_2);
            }];
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight:
        {
            [UIView animateWithDuration:0.2 animations:^{
                self.flipCameraButton.transform = CGAffineTransformMakeRotation(M_PI_2);
            }];
        }
            break;
            
        default:
            break;
    }
}

- (void)handleLongPressGestureRecognizer:(UILongPressGestureRecognizer*)longPressGestureRecognizer {
    
    switch (longPressGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (!_recording)
                [self _startCapture];
            else
                [self _resumeCapture];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            if (_recording) {
                [self _pauseCapture];
            }
        }
            break;
            
        default:
            break;
    }
}


- (void)handleShutterButtonPressed:(UIButton*)button {
        if (!_recording)
            [self _startCapture];
        else
            [self _resumeCapture];

}

- (void)handleShutterButtonReleased:(UIButton*)button {
    if (_recording) {
        [self _pauseCapture];
    }
}

- (void)timerTick {
    
    if (_activelyRecording || _videoPlayerController.playbackState == PBJVideoPlayerPlaybackStatePlaying) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            _recordingTimeRemaining -= TIMER_TICK;
            
            CGFloat progress;
            if (self.mode == kVideoRecorderModeRecording) {
                progress = 1 - (_recordingTimeRemaining / self.maxVideoDuration);
            } else {
                progress = 1 - (_recordingTimeRemaining / self.recordedVideoDuration);
            }

            progress = MAX(progress, 0);
            _recordingTimeRemaining = MAX(_recordingTimeRemaining, 0);
            
            if (_recordingTimeRemaining <= 0) {
                [self handleTimerExpired];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{

                if (self.mode == kVideoRecorderModeRecording) {
                    if ([PBJVision sharedInstance].capturedVideoSeconds >= self.minVideoDuration) {
                        [self _videoMinimumDurationRequirementMet];
                    } else {
                        
                        //We'll keep the button enabled for now and show the tooltip when user tries to continue
                        /*
                        CGFloat recordingProgress = [PBJVision sharedInstance].capturedVideoSeconds / self.minVideoDuration;
                        [UIView animateWithDuration:0.1 animations:^{
                            [self.finishRecordingButton setAlpha:(0.5 * recordingProgress)];
                        }];
                         */
                    }
                }
                    
                    [self.recordingProgressView setProgress:progress animated:YES];
                });
            }
            

        });
    }
}

- (void)_videoMinimumDurationRequirementMet {
    //Allow proceeding
    //Do nothing for now
    /*
    [UIView animateWithDuration:0.1 animations:^{
        [self.finishRecordingButton setAlpha:1.0f];
    } completion:^(BOOL finished) {
        self.finishRecordingButton.enabled = YES;
    }];
     */
}

- (void)_resetRecordingProgressViewAnimated:(BOOL)animated {
    
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            CGRect fullProgressViewFrame = self.recordingProgressView.frame;
            fullProgressViewFrame.size.width = self.view.frame.size.width;
            [self.recordingProgressView setFrame:fullProgressViewFrame];
        }];
    } else {
        CGRect fullProgressViewFrame = self.recordingProgressView.frame;
        fullProgressViewFrame.size.width = self.view.frame.size.width;
        [self.recordingProgressView setFrame:fullProgressViewFrame];
    }
}

- (void)handleTimerExpired {
    
    [self _stopTimer];
    
    if (_recording)
        [self _endCapture];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [self _resetCapture];
//    [[ZMotionManager sharedManager] startDeviceMotionUpdates];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[PBJVision sharedInstance] stopPreview];
    [_videoPlayerController stop];
//    [[ZMotionManager sharedManager] stopDeviceMotionUpdates];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

#pragma mark - Start/Stop recording methods

dispatch_source_t CreateDispatchTimer(uint64_t interval,
                                      uint64_t leeway,
                                      dispatch_queue_t queue,
                                      dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

- (void)_startTimer {
    __block typeof(self) weakSelf = self;
    _gcdRecordingTimer = [RNTimer repeatingTimerWithTimeInterval:TIMER_TICK block:^{
        [weakSelf timerTick];
    }];
}

- (void)_stopTimer {
    [_gcdRecordingTimer invalidate];
    _gcdRecordingTimer = nil;
}

- (void)_startCapture {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [self _updateCameraOrientation];
    [[PBJVision sharedInstance] startVideoCapture];
    [self _startTimer];
}

- (void)_pauseCapture {
    [[PBJVision sharedInstance] pauseVideoCapture];
    [self _stopTimer];
}

- (void)_resumeCapture {
    [self _updateCameraOrientation];
    [[PBJVision sharedInstance] resumeVideoCapture];
    [self _startTimer];
    
}

- (void)_endCapture {
    
    _recording = NO;
    _activelyRecording = NO;
    
    self.recordedVideoDuration = [[PBJVision sharedInstance] capturedVideoSeconds];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[PBJVision sharedInstance] endVideoCapture];
}

- (void)_cancelCapture {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[PBJVision sharedInstance] stopPreview];
}

- (void)_updateCameraOrientation {
    PBJCameraOrientation orientation = [[PBJVision sharedInstance] cameraOrientation];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            orientation = PBJCameraOrientationPortrait;
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = PBJCameraOrientationPortraitUpsideDown;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            orientation = PBJCameraOrientationLandscapeRight;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            orientation = PBJCameraOrientationLandscapeLeft;
            break;
            
        default:
            break;
    }
    
    [[PBJVision sharedInstance] setCameraOrientation:orientation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
        {
            [UIView animateWithDuration:duration animations:^{
                self.flipCameraButton.transform = CGAffineTransformMakeRotation(0);
            }];
        }
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            [UIView animateWithDuration:duration animations:^{
                self.flipCameraButton.transform = CGAffineTransformMakeRotation(M_PI_2);
            }];
        }
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
        {
            [UIView animateWithDuration:duration animations:^{
                self.flipCameraButton.transform = CGAffineTransformMakeRotation(-M_PI_4);
            }];
        }
            break;
            
        case UIInterfaceOrientationLandscapeRight:
        {
            [UIView animateWithDuration:duration animations:^{
                self.flipCameraButton.transform = CGAffineTransformMakeRotation(M_PI_4);
            }];
        }
            break;
            
        default:
            break;
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}
*/



- (void)_resetCapture {
    
    if (_videoPlayerController.view.superview) {
        self.mode = kVideoRecorderModeRecording;
        [_videoPlayerController stop];
        [_videoPlayerController.view removeFromSuperview];
        _previewView.hidden = NO;
    }
    
    //Set default
    if (!self.maxVideoDuration) {
        self.maxVideoDuration = MAX_VIDEO_DURATION;
    }
    _recordingTimeRemaining = self.maxVideoDuration;
    
    [self.recordingProgressView setProgress:0.f animated:YES];
    
    _longPressGestureRecognizer.enabled = YES;
    
    PBJVision *vision = [PBJVision sharedInstance];
    vision.delegate = self;
    
    self.shutterButton.hidden = NO;
    self.cancelButton.hidden = YES;
    self.saveButton.hidden = YES;
    
    self.finishRecordingButton.enabled = YES;
    self.finishRecordingButton.alpha = 1;
    
    if ([vision isCameraDeviceAvailable:PBJCameraDeviceBack]) {
        [vision setCameraDevice:PBJCameraDeviceBack];
        _flipCameraButton.hidden = NO;
        _focusButton.hidden = NO;
    } else {
        [vision setCameraDevice:PBJCameraDeviceFront];
        
#ifndef TARGET_IPHONE_SIMULATOR
        _flipCameraButton.hidden = YES;
#endif
        _focusButton.hidden = YES;
    }
    
    [vision setCameraMode:PBJCameraModeVideo];
    [vision setCameraOrientation:PBJCameraOrientationPortrait];
    [vision setFocusMode:PBJFocusModeContinuousAutoFocus];
    [vision setOutputFormat:PBJOutputFormatSquare];
    [vision setVideoRenderingEnabled:YES];
    
    [[PBJVision sharedInstance] startPreview];
}

- (IBAction)flipCameraButtonTapped:(id)sender {
    
    if ([[PBJVision sharedInstance] cameraDevice] == PBJCameraDeviceFront) {
        _focusButton.hidden = NO;
        [[PBJVision sharedInstance] setCameraDevice:PBJCameraDeviceBack];
    } else {
        _focusButton.hidden = YES;
        [[PBJVision sharedInstance] setCameraDevice:PBJCameraDeviceFront];
    }
}

- (IBAction)focusButtonTapped:(id)sender {
}

- (IBAction)onionButtonTapped:(id)sender {
}

- (IBAction)saveButtonTapped:(id)sender {
    _longPressGestureRecognizer.enabled = NO;
    _longPressGestureRecognizer.enabled = YES;
    [self videoRecordingComplete];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)closeButtonTapped:(id)sender {
    [self showCancelRecordingAlertView];
}

- (IBAction)finishRecordingButtonTapped:(id)sender {
    
    if ([PBJVision sharedInstance].capturedVideoSeconds < self.minVideoDuration) {
        //Show tooltip
        //Get point of marker/stop
//        CGPoint minimumRecordingStop = self.recordingProgressView.
        if ([self.delegate respondsToSelector:@selector(videoPreviewAttemptedWithMinimumDurationMet:)]) {
            [self.delegate videoPreviewAttemptedWithMinimumDurationMet:NO];
        }
        
        ZProgressViewStop *minStop = [self.recordingProgressView.stops firstObject];
        if (minStop) {
            CGPoint minStopViewOrigin = minStop.stopView.frame.origin;
            CGPoint convertedMinStopViewOrigin = [self.view convertPoint:minStopViewOrigin fromView:self.recordingProgressView];
            R20PopoverView *minimumRecordingPopover =  [R20PopoverView showPopoverAtPoint:convertedMinStopViewOrigin
                                                                                   inView:self.view
                                                                                 withText:NSLocalizedString(@"Record at least to this point", @"Popup that instructs user that the minimum recording length is to the white marker that this popup is pointing at")
                                                                                 delegate:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [minimumRecordingPopover dismiss];
            });
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(videoPreviewAttemptedWithMinimumDurationMet:)]) {
            [self.delegate videoPreviewAttemptedWithMinimumDurationMet:YES];
        }
        [self handleTimerExpired];
    }
}

- (void)showCancelRecordingAlertView {
    _cancelRecordingAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cancel Recording?", @"Video reviews - user tapped on close button")
                                                           message:NSLocalizedString(@"Any video recorded in this session will be lost", @"Message to user when they close the video revies page")
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [_cancelRecordingAlertView show];
}

- (void)_cancelRecording {
    
    if ([self.delegate respondsToSelector:@selector(videoRecordingSessionCancelled)]) {
        [self.delegate videoRecordingSessionCancelled];
    }
    
    [self _cancelCapture];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelButtonTapped:(id)sender {
        _discardAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Discard?", @"Alert view title asking user if they want to discard the video")
                                                              message:NSLocalizedString(@"Discard this video and start over?", @"Alert view message - asks user if they want to discard video")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                    otherButtonTitles:NSLocalizedString(@"Discard", nil), nil];
        [_discardAlertView show];
}


- (void)handleTapGestureRecognizer:(UITapGestureRecognizer*)tapGestureRecognizer {
    CGPoint tapPoint = [tapGestureRecognizer locationInView:_previewView];
    
    // auto focus is occuring, display focus view
    CGPoint point = tapPoint;
    
    CGRect focusFrame = _focusView.frame;
#if defined(__LP64__) && __LP64__
    focusFrame.origin.x = rint(point.x - (focusFrame.size.width * 0.5));
    focusFrame.origin.y = rint(point.y - (focusFrame.size.height * 0.5));
#else
    focusFrame.origin.x = rintf(point.x - (focusFrame.size.width * 0.5f));
    focusFrame.origin.y = rintf(point.y - (focusFrame.size.height * 0.5f));
#endif
    [_focusView setFrame:focusFrame];
    
    [_previewView addSubview:_focusView];
    [_focusView startAnimation];
    
    CGPoint adjustPoint = [PBJVisionUtilities convertToPointOfInterestFromViewCoordinates:tapPoint inFrame:_previewView.frame];
    
    if ((!_isFocusing || [_lastFocusTime timeIntervalSinceNow] < -5.0)  &&
        (!_isAdjustingExposure || [_lastExposureTime timeIntervalSinceNow] < -5.0)) {
        [[PBJVision sharedInstance] focusAtAdjustedPointOfInterest:adjustPoint];
    } else {
        _focusQueued = YES;
        _queuedFocusPoint = adjustPoint;
    }
}

//Capture Delegate

- (void)visionDidStartVideoCapture:(PBJVision *)vision {
    
    _recording = YES;
    _activelyRecording = YES;
}

- (void)visionDidPauseVideoCapture:(PBJVision *)vision {
    _activelyRecording = NO;
}

- (void)visionDidResumeVideoCapture:(PBJVision *)vision {
    _activelyRecording = YES;
}

- (void)vision:(PBJVision *)vision capturedVideo:(NSDictionary *)videoDict error:(NSError *)error {
    

    
    if (error) {
        return;
    }
    
    _currentVideo = videoDict;
    NSString *videoPath = [_currentVideo objectForKey:PBJVisionVideoPathKey];
    [self _videoSavedAtPath:videoPath];
    self.videoPath = videoPath;
}

- (void)vision:(PBJVision *)vision didChangeCleanAperture:(CGRect)cleanAperture
{
}

- (void)visionWillStartFocus:(PBJVision *)vision
{
    _isFocusing = YES;
    _lastFocusTime = [NSDate date];
}

- (void)visionDidStopFocus:(PBJVision *)vision
{
    _isFocusing = NO;
    _lastFocusTime = nil;
    
    if (!_isAdjustingExposure) {
        if (_focusQueued) {
            [self _processQueuedFocus];
        } else {
            if (_focusView && [_focusView superview]) {
                [_focusView stopAnimation];
            }
        }
    }
}

- (void)visionWillChangeExposure:(PBJVision *)vision
{
    _isAdjustingExposure = YES;
    _lastExposureTime = [NSDate date];
}

- (void)visionDidChangeExposure:(PBJVision *)vision {

    _isAdjustingExposure = NO;
    _lastExposureTime = nil;

    if (!_isFocusing) {
        if (_focusQueued) {
            [self _processQueuedFocus];
        } else {
            if (_focusView && [_focusView superview]) {
                [_focusView stopAnimation];
            }
        }
    }
}

- (void)_processQueuedFocus {
    if (_focusQueued) {
        [[PBJVision sharedInstance] focusAtAdjustedPointOfInterest:_queuedFocusPoint];
        _queuedFocusPoint = CGPointZero;
        _focusQueued = NO;
    }
}


- (void)_videoSavedAtPath:(NSString*)path {

    [self _playVideoAtPath:path];
    
    self.shutterButton.hidden = YES;
    self.flipCameraButton.hidden = YES;
    
    self.saveButton.hidden = NO;
    self.cancelButton.hidden = NO;
}

- (void)_playVideoAtPath:(NSString*)path {
    
    self.mode = kVideoRecorderModePlayback;
    [[PBJVision sharedInstance] stopPreview];

    _videoPlayerController = [[PBJVideoPlayerController alloc] init];
    _videoPlayerController.delegate = self;
    _videoPlayerController.view.frame = self.previewView.frame;
    
    [self addChildViewController:_videoPlayerController];
    [self.view addSubview:_videoPlayerController.view];
    [_videoPlayerController didMoveToParentViewController:self];
    
    _videoPlayerController.videoPath = path;
    
    [_videoPlayerController setPlaybackLoops:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_videoPlayerController playFromBeginning];
    });

}

- (void)videoRecordingComplete {
    
    if ([self.delegate respondsToSelector:@selector(videoRecordedAtPath:)]) {
        [self.delegate videoRecordedAtPath:self.videoPath];
    }
}

#pragma mark - PBJVideoPlayerControllerDelegate

- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer{
//    [_videoPlayerController playFromBeginning];
    if (self.mode == kVideoRecorderModePlayback) {
        self.previewView.hidden = YES;
    }
}

- (void)videoPlayerPlaybackStateDidChange:(PBJVideoPlayerController *)videoPlayer {
    
    switch (videoPlayer.playbackState) {
        case PBJVideoPlayerPlaybackStatePlaying:
        {
            [self _startTimer];
        }
            break;
            
        case PBJVideoPlayerPlaybackStatePaused:
        case PBJVideoPlayerPlaybackStateStopped:
        case PBJVideoPlayerPlaybackStateFailed:
        {
            [self _stopTimer];
        }
            break;
            
        default:
            break;
    }
}

- (void)videoPlayerPlaybackWillStartFromBeginning:(PBJVideoPlayerController *)videoPlayer {
    [self _resetPlayback];
}

- (void)videoPlayerPlaybackDidEnd:(PBJVideoPlayerController *)videoPlayer {
    if (videoPlayer.playbackState == PBJVideoPlayerPlaybackStatePlaying) {
        [self _resetPlayback];
        [self _startTimer];
    }
}

- (void)videoPlayerPlaybackEnded {
    [self videoPlayerPlaybackDidEnd:_videoPlayerController];
}

- (void)_resetPlayback {
    _recordingTimeRemaining = self.recordedVideoDuration;
//    [self _resetRecordingProgressViewAnimated:NO];
    [self.recordingProgressView setProgress:0.f];
}


#pragma mark - UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == _discardAlertView) {
        if (buttonIndex != _discardAlertView.cancelButtonIndex) {
            [self _resetCapture];
            if ([self.delegate respondsToSelector:@selector(videoRecordingDiscarded)]) {
                [self.delegate videoRecordingDiscarded];
            }
        }
    } else if (alertView == _cancelRecordingAlertView) {
        if (buttonIndex != _cancelRecordingAlertView.cancelButtonIndex) {
            [self _cancelRecording];
        }
    }
}

#pragma mark - Setters
- (void)setMode:(VideoRecorderMode)mode {
    _mode = mode;
    
    if (_mode == kVideoRecorderModeRecording) {
        self.recordingProgressView.showStops = YES;
        [self updateControlViewBackgroundColor];
    } else {
        self.finishRecordingButton.alpha = 0;
        self.finishRecordingButton.enabled = NO;
        self.recordingProgressView.showStops = NO;
        [self updateControlViewBackgroundColor];
    }
}

- (void)setControlViewBackgroundColor:(UIColor *)backgroundColor forMode:(VideoRecorderMode)mode {
    switch (mode) {
        case kVideoRecorderModeRecording:
            _controlViewRecordingModeBackgroundColor = backgroundColor;
            break;
            
        case kVideoRecorderModePlayback:
            _controlViewPlaybackModeBackgroundColor = backgroundColor;
            break;
            
        default:
            break;
    }
    
    [self updateControlViewBackgroundColor];
}

- (void)updateControlViewBackgroundColor {
    switch (self.mode) {
        case kVideoRecorderModeRecording:
            self.controlsContainerView.backgroundColor = _controlViewRecordingModeBackgroundColor;
            break;
            
        case kVideoRecorderModePlayback:
            self.controlsContainerView.backgroundColor = _controlViewPlaybackModeBackgroundColor;
            break;
            
        default:
            break;
    }
}

@end
