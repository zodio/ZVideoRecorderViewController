//
//  ZViewController.h
//  ZVideoRecorderExample
//
//  Created by Jai Govindani on 3/1/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZVideoRecorderViewController.h"

@interface ZViewController : UIViewController <VideoRecorderDelegate>

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
- (IBAction)takeVideoButtonTapped:(id)sender;
@end
