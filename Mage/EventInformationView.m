//
//  EventInformationView.m
//  MAGE
//
//  Created by William Newman on 1/29/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventInformationView.h"

@interface EventInformationView ()
@property (strong, nonatomic) id<AppContainerScheming> scheme;
@end

@implementation EventInformationView

- (void) didMoveToSuperview {
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.nameLabel.textColor = [self.scheme.colorScheme.onBackgroundColor colorWithAlphaComponent:0.87];
    self.nameLabel.font = self.scheme.typographyScheme.headline6Font;
    self.descriptionLabel.textColor = [self.scheme.colorScheme.onBackgroundColor colorWithAlphaComponent:0.6];
    self.descriptionLabel.font = self.scheme.typographyScheme.subtitle2Font;
}

@end
