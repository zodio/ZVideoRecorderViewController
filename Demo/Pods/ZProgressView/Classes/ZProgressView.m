//
//  ZProgressView.m
//  ZProgressViewExample
//
//  Created by Jai Govindani on 3/2/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#define STOP_TAG    100

#import "ZProgressView.h"
#import "ZProgressViewStop.h"

@interface ZProgressView ()

@property (strong, nonatomic) UIView *progressBarView;

@end

@implementation ZProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)setup {
    _progressBarView = [[UIView alloc] initWithFrame:CGRectInset(self.bounds, 0, 2)];
    [self addSubview:_progressBarView];
    _showStops = YES;
    
    self.autoresizesSubviews = YES;
    self.clipsToBounds = YES;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (NSMutableArray*)stops {
    if (!_stops) {
        _stops = [NSMutableArray array];
    }
    
    return _stops;
}

- (void)addStopAtPosition:(CGFloat)position {
    
    if (![self _stopExistsAtPosition:position]) {
        ZProgressViewStop *stopToAdd = [ZProgressViewStop stopAtPosition:position];
        [self.stops addObject:stopToAdd];
        stopToAdd.stopView.hidden = !self.showStops;
        [stopToAdd placeInProgressView:self];
    }

}

- (void)removeStopAtPosition:(CGFloat)position {
    
    if ([self _stopExistsAtPosition:position]) {
        ZProgressViewStop *stopToRemove;
        
        for (ZProgressViewStop *stop in self.stops) {
            if (stop.position == position) {
                stopToRemove = stop;
            }
        }
        
        [stopToRemove removeFromProgressView];
        [self.stops removeObject:stopToRemove];
    }
}

- (void)removeAllStops {
    for (ZProgressViewStop *stop in self.stops) {
        [stop removeFromProgressView];
    }
    
    [self.stops removeAllObjects];
}

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    
    //Default is 0.5sec for entire bar
    //Find delta
    //UPDATE: This kind of animating doesn't work smoothly
//    CGFloat progressDelta = fabsf(_progress - progress);
//    NSTimeInterval animationDuration = 0.5 * progressDelta;
    
    _progress = progress;
    NSInteger progressBarWidth = floorf(progress * self.frame.size.width);
    CGRect progressBarFrame = _progressBarView.frame;
    progressBarFrame.size.width = progressBarWidth;
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            [_progressBarView setFrame:progressBarFrame];
        }];
    } else {
        [_progressBarView setFrame:progressBarFrame];
    }
}

- (void)setProgressBarColor:(UIColor *)progressBarColor {
    _progressBarColor = progressBarColor;
    [_progressBarView setBackgroundColor:_progressBarColor];
}

- (void)setShowStops:(BOOL)showStops {
    if (_showStops != showStops) {
        _showStops = showStops;
        for (ZProgressViewStop *stop in self.stops) {
            stop.stopView.hidden = !_showStops;
        }
    }
}

#pragma mark - Private

- (BOOL)_stopExistsAtPosition:(CGFloat)position {
    for (ZProgressViewStop *stop in self.stops) {
        if (stop.position == position) {
            return YES;
        }
    }
    
    return NO;
}

@end
