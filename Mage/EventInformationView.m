//
//  EventInformationView.m
//  MAGE
//
//  Created by William Newman on 1/29/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventInformationView.h"
#import "Theme+UIResponder.h"

@implementation EventInformationView

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.nameLabel.textColor = [UIColor primaryText];
    self.descriptionLabel.textColor = [UIColor secondaryText];
}

@end
