//
//  ZProgressView.h
//  ZProgressViewExample
//
//  Created by Jai Govindani on 3/2/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZProgressView : UIView

/**
 *  The current progress of the progress view
 */
@property (nonatomic) CGFloat progress;

/**
 *  Track color for the progress view (foreground - the moving part)
 */
@property (strong, nonatomic) UIColor *progressBarColor;

/**
 *  An array of CGFloat wrapped in NSNumber to indicate where to show stops
 */
@property (strong, nonatomic) NSMutableArray *stops;

/**
 *  Indicate whether stops should be visible or not
 */
@property (nonatomic) BOOL showStops;

/**
 *  Add a stop at the specified position.
 *
 *  @param position Position indicated by a CGFloat between 0 and 1
 *
 *  @discussion A stop is a vertical 1 pixel marker with the same color as the background color
 */
- (void)addStopAtPosition:(CGFloat)position;

/**
 *  Remove a stop at the specified position (if one is present)
 *
 *  @param position The stop position to remove
 */
- (void)removeStopAtPosition:(CGFloat)position;

/**
 *  Removes all stops
 */
- (void)removeAllStops;

/**
 *  Sets the progress of the Progress View - default animation is non-animated
 *
 *  @param progress Progress to set as a CGFloat between 0 and 1
 */
- (void)setProgress:(CGFloat)progress;

/**
 *  Similar to setProgress: except with an option to animate
 *
 *  @param progress See setProgress:
 *  @param animated Boolean value to specify whether the progress setting should be animated or not
 */
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end
