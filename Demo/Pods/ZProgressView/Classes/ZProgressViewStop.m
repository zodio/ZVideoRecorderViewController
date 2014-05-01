//
//  ZProgressViewStop.m
//  ZProgressViewExample
//
//  Created by Jai Govindani on 3/2/14.
//  Copyright (c) 2014 Zodio. All rights reserved.
//

#import "ZProgressViewStop.h"
#import "ZProgressView.h"

@implementation ZProgressViewStop

+ (instancetype)stopAtPosition:(CGFloat)position {
    ZProgressViewStop *stop = [[ZProgressViewStop alloc] init];
    stop.position = position;
    return stop;
}

- (id)init {
    if (self = [super init]) {
        //Default color
        self.stopViewColor = [UIColor whiteColor];
        
        //Default width
        self.width = 1.0f;
    }
    
    return self;
}

- (void)placeInProgressView:(ZProgressView*)progressView {
    
    if (progressView) {
        self.progressView = progressView;
        
        NSInteger stopViewXPosition = floorf(self.position * progressView.frame.size.width);
        [self.stopView setFrame:CGRectMake(stopViewXPosition, 0,
                                                                 self.width, progressView.frame.size.height)];
        self.stopView.backgroundColor = self.stopViewColor;
        
        [progressView addSubview:self.stopView];
        [progressView bringSubviewToFront:self.stopView];
    }
}

- (void)removeFromProgressView {
    if (self.stopView.superview) {
        [self.stopView removeFromSuperview];
        self.stopView = nil;
    }
}

- (UIView*)stopView {
    if (!_stopView) {
        _stopView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    return _stopView;
}

@end
