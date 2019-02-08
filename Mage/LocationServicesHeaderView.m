//
//  LocationServicesHeaderView.m
//  MAGE
//
//  Created by William Newman on 2/5/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationServicesHeaderView.h"
#import "Theme+UIResponder.h"
#import "UIColor+Mage.h"

@implementation LocationServicesHeaderView

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor tableBackground];
    self.openSettingsTapped.tintColor = [UIColor brand];
    self.settingsLabel.textColor = [UIColor brand];
}

- (IBAction)onOpenSettingsTapped:(id)sender {
    [self.delegate openSettingsTapped];
}

@end
