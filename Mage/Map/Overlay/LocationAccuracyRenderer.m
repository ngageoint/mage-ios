//
//  LcoationAccuracyRenderer.m
//  MAGE
//
//  Created by William Newman on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationAccuracyRenderer.h"
#import "LocationAccuracy.h"

@implementation LocationAccuracyRenderer

- (instancetype)initWithOverlay:(LocationAccuracy *) overlay {
    self = [super initWithOverlay:overlay];
    if (self) {
        self.lineWidth = 1.0f;
        
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:overlay.timestamp];
        if (interval <= 600) {
            self.fillColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:.1f];
            self.strokeColor = [UIColor blueColor];
        } else if (interval <= 1200) {
            self.fillColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:.1f];
            self.strokeColor = [UIColor yellowColor];
        } else {
            self.fillColor = [UIColor colorWithRed:1 green:.5 blue:0 alpha:.1f];
            self.strokeColor = [UIColor orangeColor];
        }
    }
    
    return self;
}

@end
