//
//  AccuracyOverlayView.m
//  MAGE
//
//  Created by William Newman on 5/6/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationAccuracyRenderer.h"
#import "ObservationAccuracy.h"
#import "MAGE-Swift.h"

@implementation ObservationAccuracyRenderer

- (instancetype)initWithOverlay:(ObservationAccuracy *) overlay {
    self = [super initWithOverlay:overlay];
    if (self) {
        self.lineWidth = 1.0f;
        self.fillColor = [[UIColor labelColor] colorWithAlphaComponent:0.2f];
        self.strokeColor = [UIColor labelColor];
    }
    
    return self;
}

- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        if (containerScheme.colorScheme.primaryColor != nil) {
            self.fillColor = [containerScheme.colorScheme.primaryColorVariant colorWithAlphaComponent:0.2f];
            self.strokeColor = containerScheme.colorScheme.primaryColorVariant;
        }
    }
}

@end
