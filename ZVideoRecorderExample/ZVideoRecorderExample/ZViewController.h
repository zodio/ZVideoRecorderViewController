//
//  ZViewController.h
//  ZVideoRecorderExample
//
//  Created by Jai Govindani on 3/1/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
- (IBAction)takeVideoButtonTapped:(id)sender;
@end
