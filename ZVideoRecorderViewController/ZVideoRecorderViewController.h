//
//  ZVideoRecorderViewController.h
//  VideoReviewsExample
//
//  Created by Jai Govindani on 2/23/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZProgressView;

typedef enum {
    kVideoRecorderModeRecording =   0,
    kVideoRecorderModePlayback
} VideoRecorderMode;

@protocol VideoRecorderDelegate <NSObject>

@required
- (void)videoRecordedAtPath:(NSString*)path;

@end

@interface ZVideoRecorderViewController : UIViewController

/**
 *  View to contain the layer that displays data from the camera
 */
@property (weak, nonatomic) IBOutlet UIView *previewView;

/**
 *  Container view that holds the shutter button, flip camera button, and any other accessories
 */
@property (weak, nonatomic) IBOutlet UIView *controlsContainerView;

/**
 *  Button to flip camera source (back/front) - hidden if device doesn't have dual cameras
 */
@property (weak, nonatomic) IBOutlet UIButton *flipCameraButton;

/**
 *  Unused
 */
@property (weak, nonatomic) UIButton *focusButton;

/**
 *  Recording progress view counts down to maxDuration
 */
@property (weak, nonatomic) IBOutlet ZProgressView *recordingProgressView;

/**
 *  Shutter button - press + hold to capture video
 */
@property (weak, nonatomic) IBOutlet UIButton *shutterButton;

/**
 *  The save button is used at the end of the video capture session to save and upload the video review
 */
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

/**
 *  Cancel button when in play mode - dismisses playback and goes back to record
 */
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

/**
 *  Close button on top left of screen to disimss the recording view controller
 */
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *finishRecordingButton;
@property (nonatomic) CGFloat minVideoDuration;
@property (nonatomic) CGFloat maxVideoDuration;
@property (nonatomic) CGFloat recordedVideoDuration;
@property (nonatomic) VideoRecorderMode mode;
@property (strong, nonatomic) NSString *videoPath;
@property (nonatomic) id<VideoRecorderDelegate> delegate;

- (IBAction)flipCameraButtonTapped:(id)sender;
- (IBAction)focusButtonTapped:(id)sender;
- (IBAction)onionButtonTapped:(id)sender;
- (IBAction)saveButtonTapped:(id)sender;
- (IBAction)cancelButtonTapped:(id)sender;
- (IBAction)closeButtonTapped:(id)sender;
- (IBAction)finishRecordingButtonTapped:(id)sender;

+ (instancetype)videoRecorder;
- (void)videoRecordingComplete;

- (void)setControlViewBackgroundColor:(UIColor*)backgroundColor forMode:(VideoRecorderMode)mode;

@end
