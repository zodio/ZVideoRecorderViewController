//
//  ZProgressViewStop.h
//  ZProgressViewExample
//
//  Created by Jai Govindani on 3/2/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZProgressView;

@interface ZProgressViewStop : NSObject

@property (nonatomic) CGFloat position;
@property (nonatomic) CGFloat width;

@property (strong, nonatomic) UIView *stopView;
@property (strong, nonatomic) UIColor *stopViewColor;

@property (weak, nonatomic) ZProgressView *progressView;

+ (instancetype)stopAtPosition:(CGFloat)position;
- (void)placeInProgressView:(ZProgressView*)progressView;
- (void)removeFromProgressView;

@end
