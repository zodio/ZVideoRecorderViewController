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
    [self presentViewController:videoRecorder animated:YES completion:nil];
    
}
@end
