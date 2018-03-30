//
//  ObservationAddImportantTableViewCell.m
//  MAGE
//
//  Created by William Newman on 10/27/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//
@import HexColors;

#import "ObservationAddImportantTableViewCell.h"
#import "User.h"
#import "Theme+UIResponder.h"

@interface ObservationAddImportantTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *flagIcon;
@property (weak, nonatomic) IBOutlet UIButton *flagButton;

@end

@implementation ObservationAddImportantTableViewCell

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.flagIcon.tintColor = [UIColor colorWithHexString:@"AB47BC" alpha:0.87];
    [self.flagButton setTitleColor:[UIColor activeIconWithColor:[UIColor colorWithHexString:@"AB47BC" alpha:0.87]] forState:UIControlStateNormal];
}

- (IBAction) onUpdateImportantTapped:(id)sender {
    if (self.observationImportantDelegate) {
        [self.observationImportantDelegate flagObservationImportant];
    }
}

@end
