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

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *flipCameraButton;
@property (weak, nonatomic) UIButton *focusButton;
@property (weak, nonatomic) IBOutlet ZProgressView *recordingProgressView;
@property (weak, nonatomic) IBOutlet UIButton *shutterButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
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

@end
