//
//  ObservationStatusErrorTableViewCell.m
//  MAGE
//
//  Created by William Newman on 4/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationStatusErrorTableViewCell.h"
#import "Theme+UIResponder.h"

@implementation ObservationStatusErrorTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    self.errorLabel.text = [observation errorMessage];
}

@end
