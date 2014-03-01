//
//  ZVideoRecorderViewController.m
//  VideoReviewsExample
//
//  Created by Jai Govindani on 2/23/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#import "ZVideoRecorderViewController.h"
#import <PBJVision/PBJVision.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <GLKit/GLKit.h>

#import <PBJVideoPlayer/PBJVideoPlayerController.h>
#import "RNTimer.h"
#import <MBProgressHUD/MBProgressHUD.h>

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
    BOOL _recording;
    BOOL _activelyRecording;
    
    __block NSDictionary *_currentVideo;
    
    NSTimer *_recordingTimer;
    CGFloat _recordingDuration;
    
    PBJVideoPlayerController *_videoPlayerController;
    UIAlertView *_discardAlertView;
    UIAlertView *_cancelRecordingAlertView;
    RNTimer *_gcdRecordingTimer;
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
    
    //Set up the preview view
//    [_previewView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.width.equalTo(self.view.mas_width);
//        make.height.equalTo(self.view.mas_width);
//    }];
    
//    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerY.equalTo(self.recordingProgressView.mas_centerY);
//        make.centerX.equalTo(self.recordingProgressView.mas_centerY);
//    }];
    
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
    /*
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureRecognizer:)];
    _tapGestureRecognizer.delegate = self;
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    _tapGestureRecognizer.enabled = NO;
    [_previewView addGestureRecognizer:_tapGestureRecognizer];
     */
    
    [self.shutterButton addGestureRecognizer:_longPressGestureRecognizer];
    
//    [self.shutterButton addTarget:self action:@selector(handleShutterButtonPressed:) forControlEvents:UIControlEventTouchDown];
//    [self.shutterButton addTarget:self action:@selector(handleShutterButtonReleased:) forControlEvents:UIControlEventTouchUpInside];
//    [self.shutterButton addTarget:self action:@selector(handleShutterButtonReleased:) forControlEvents:UIControlEventTouchDragExit];
//    [self.shutterButton addTarget:self action:@selector(handleShutterButtonReleased:) forControlEvents:UIControlEventTouchUpOutside];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayerPlaybackEnded)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
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
            //            _activelyRecording = NO;
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
            
            _recordingDuration -= TIMER_TICK;
            CGFloat progress = _recordingDuration / self.maxVideoDuration;

            progress = MAX(progress, 0);
            _recordingDuration = MAX(_recordingDuration, 0);
            
            if (_recordingDuration <= 0) {
                [self handleTimerExpired];

            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.recordingProgressView setProgress:progress animated:YES];
                [UIView animateWithDuration:TIMER_TICK animations:^{
                    
                    CGRect progressViewFrame = self.recordingProgressView.frame;
                    progressViewFrame.size.width = self.view.frame.size.width * progress;
                    self.recordingProgressView.frame = progressViewFrame;
                }];
            });
        });
    }
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[PBJVision sharedInstance] stopPreview];
    [_videoPlayerController stop];
    
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
//    [_recordingTimer invalidate];
//    dispatch_source_cancel(_gcdRecordingTimer);
    [_gcdRecordingTimer invalidate];
    _gcdRecordingTimer = nil;
}

- (void)_startCapture {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    _instructionLabel.text = @"Recording...";
    [[PBJVision sharedInstance] startVideoCapture];
    [self _startTimer];
}

- (void)_pauseCapture {
    [[PBJVision sharedInstance] pauseVideoCapture];
    _instructionLabel.text = @"Paused";
    [self _stopTimer];
}

- (void)_resumeCapture {
    _instructionLabel.text = @"Recording...";
    [[PBJVision sharedInstance] resumeVideoCapture];
    [self _startTimer];
    
}

- (void)_endCapture {
    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.labelText = @"Processing...";
    
//    dispatch_sync(dispatch_get_main_queue(), ^{

//    });

    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[PBJVision sharedInstance] endVideoCapture];
//    _instructionLabel.text = @"Saving...";
//    [self _stopTimer];
    
}

- (void)_cancelCapture {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[PBJVision sharedInstance] stopPreview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_resetCapture {
    
    if (_videoPlayerController.view.superview) {
        [_videoPlayerController stop];
        [_videoPlayerController.view removeFromSuperview];
        _previewView.hidden = NO;
    }
    
    //Set default
    if (!self.maxVideoDuration) {
        self.maxVideoDuration = MAX_VIDEO_DURATION;
    }
    _recordingDuration = self.maxVideoDuration;
    
//    [_recordingProgressView setProgress:1.0f animated:YES];
    CGRect progressViewFrame = self.recordingProgressView.frame;
    progressViewFrame.size.width = self.view.frame.size.width;
    [UIView animateWithDuration:0.5 animations:^{
        self.recordingProgressView.frame = progressViewFrame;
    }];
    
    _longPressGestureRecognizer.enabled = YES;
    
    PBJVision *vision = [PBJVision sharedInstance];
    vision.delegate = self;
    
    self.shutterButton.hidden = NO;
    self.cancelButton.hidden = YES;
    self.saveButton.hidden = YES;
    
    if ([vision isCameraDeviceAvailable:PBJCameraDeviceBack]) {
        [vision setCameraDevice:PBJCameraDeviceBack];
        _flipCameraButton.hidden = NO;
        _focusButton.hidden = NO;
    } else {
        [vision setCameraDevice:PBJCameraDeviceFront];
        _flipCameraButton.hidden = YES;
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

- (void)showCancelRecordingAlertView {
    _cancelRecordingAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cancel Recording?", @"Video reviews - user tapped on close button")
                                                           message:NSLocalizedString(@"Any video recorded in this session will be lost", @"Message to user when they close the video revies page")
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                 otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [_cancelRecordingAlertView show];
}

- (void)_cancelRecording {
    [self _cancelCapture];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelButtonTapped:(id)sender {
//    Ask user if they want to upload
        _discardAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Discard?", @"Alert view title asking user if they want to discard the video")
                                                              message:NSLocalizedString(@"Discard this video and start over?", @"Alert view message - asks user if they want to discard video")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                    otherButtonTitles:NSLocalizedString(@"Discard", nil), nil];
        [_discardAlertView show];
}


- (void)handleTapGestureRecognizer:(UITapGestureRecognizer*)tapGestureRecognizer {
    
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
    
    _recording = NO;
    _activelyRecording = NO;
    
    if (error) {
        return;
    }
    
    _currentVideo = videoDict;
    NSString *videoPath = [_currentVideo objectForKey:PBJVisionVideoPathKey];
    [_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:videoPath] completionBlock:^(NSURL *assetURL, NSError *error1) {
        
//        UIAlertView *doneAlert = [[UIAlertView alloc] initWithTitle:@"Saved" message:@"Recording saved" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
//        [doneAlert show];
//        [MBProgressHUD hideHUDForView:self.view animated:YES];
        _instructionLabel.text = @"Saved";
        [self _videoSavedAtPath:videoPath];
        self.videoPath = videoPath;
        
    }];
}

- (void)_videoSavedAtPath:(NSString*)path {

    [self _playVideoAtPath:path];
    
    self.shutterButton.hidden = YES;
    self.flipCameraButton.hidden = YES;
    
    self.saveButton.hidden = NO;
    self.cancelButton.hidden = NO;
}

- (void)_playVideoAtPath:(NSString*)path {
    
    [[PBJVision sharedInstance] stopPreview];
    self.previewView.hidden = YES;
    
    _videoPlayerController = [[PBJVideoPlayerController alloc] init];
    _videoPlayerController.delegate = self;
    _videoPlayerController.view.frame = self.previewView.frame;
    
    [self addChildViewController:_videoPlayerController];
    [self.view addSubview:_videoPlayerController.view];
    [_videoPlayerController didMoveToParentViewController:self];
    
    _videoPlayerController.videoPath = path;
    
    [_videoPlayerController setPlaybackLoops:YES];
    [_videoPlayerController playFromBeginning];
}

- (void)videoRecordingComplete {
    
    if ([self.delegate respondsToSelector:@selector(videoRecordedAtPath:)]) {
        [self.delegate videoRecordedAtPath:self.videoPath];
    }
}

#pragma mark - PBJVideoPlayerControllerDelegate

- (void)videoPlayerReady:(PBJVideoPlayerController *)videoPlayer{

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
    _recordingDuration = self.maxVideoDuration;
    [self _resetRecordingProgressViewAnimated:NO];
}


#pragma mark - UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == _discardAlertView) {
        if (buttonIndex != _discardAlertView.cancelButtonIndex) {
            //Upload the video
//            [[ZVideoUploader sharedInstance] uploadVideoAtPath:_videoPath];
            [self _resetCapture];
        }
    } else if (alertView == _cancelRecordingAlertView) {
        if (buttonIndex != _cancelRecordingAlertView.cancelButtonIndex) {
            [self _cancelRecording];
        }
    }
}

@end
