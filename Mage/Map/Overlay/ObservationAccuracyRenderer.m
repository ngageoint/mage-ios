//
//  AccuracyOverlayView.m
//  MAGE
//
//  Created by William Newman on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationAccuracyRenderer.h"
#import "ObservationAccuracy.h"

@implementation ObservationAccuracyRenderer

- (instancetype)initWithOverlay:(ObservationAccuracy *) overlay {
    self = [super initWithOverlay:overlay];
    if (self) {
        self.lineWidth = 1.0f;
        self.fillColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:.1f];
        self.strokeColor = [UIColor blueColor];
    }
    
    return self;
}

@end
