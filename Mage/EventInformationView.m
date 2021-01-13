//
//  EventInformationView.m
//  MAGE
//
//  Created by William Newman on 1/29/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventInformationView.h"

@interface EventInformationView ()
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation EventInformationView

- (void) didMoveToSuperview {
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.nameLabel.textColor = self.scheme.colorScheme.primaryColor;
    self.descriptionLabel.textColor = [self.scheme.colorScheme.onBackgroundColor colorWithAlphaComponent:0.6];
}

@end
