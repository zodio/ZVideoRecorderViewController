//
//  ZViewController.m
//  ZVideoRecorderExample
//
//  Created by Jai Govindani on 3/1/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#import "ZViewController.h"
#import "ZVideoRecorderViewController.h"

@interface ZViewController ()

@end

@implementation ZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)takeVideoButtonTapped:(id)sender {
    
    ZVideoRecorderViewController *videoRecorder = [ZVideoRecorderViewController videoRecorder];
    videoRecorder.maxVideoDuration = 10.0f;
    videoRecorder.minVideoDuration = 5.0f;
    videoRecorder.delegate = self;
    [self presentViewController:videoRecorder animated:YES completion:nil];
    
}

- (void)videoRecordedAtPath:(NSString *)path {
    [self.infoLabel setText:[NSString stringWithFormat:@"Video recorded at path: %@", path]];
}

@end
