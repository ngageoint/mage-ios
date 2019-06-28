//
//  OrView.m
//  MAGE
//
//  Created by Dan Barela on 5/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OrView.h"
#import "Theme+UIResponder.h"

@interface OrView()

@property (weak, nonatomic) IBOutlet UILabel *orLabel;
@property (weak, nonatomic) IBOutlet UIView *rightLine;
@property (weak, nonatomic) IBOutlet UIView *leftLine;

@end

@implementation OrView

- (void) themeDidChange:(MageTheme)theme {
    self.orLabel.textColor = [UIColor secondaryText];
    self.rightLine.backgroundColor = [UIColor secondaryText];
    self.leftLine.backgroundColor = [UIColor secondaryText];
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

@end
