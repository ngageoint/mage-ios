//
//  FormDefaultsSectionHeader.m
//  MAGE
//
//  Created by William Newman on 2/4/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FormDefaultsSectionHeader.h"
#import "Theme+UIResponder.h"

@implementation FormDefaultsSectionHeader

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor tableBackground];
    self.headerLabel.textColor = [UIColor secondaryText];
    self.resetButton.tintColor = [UIColor flatButton];
}

- (IBAction)onResetDefaultsTapped:(id)sender {
    [self.delegate onResetDefaultsTapped];
}

@end
