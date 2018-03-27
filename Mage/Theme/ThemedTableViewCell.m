//
//  ThemedTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 3/27/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ThemedTableViewCell.h"
#import "Theme+UIResponder.h"

@implementation ThemedTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

@end
