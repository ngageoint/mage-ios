//
//  LocationDisplayHeader.m
//  MAGE
//
//  Created by William Newman on 2/8/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "DisplaySettingsHeader.h"
#import "Theme+UIResponder.h"
#import "UIColor+Mage.h"

@implementation DisplaySettingsHeader

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.label.textColor = [UIColor brand];
    self.backgroundColor = [UIColor tableBackground];
}

@end
