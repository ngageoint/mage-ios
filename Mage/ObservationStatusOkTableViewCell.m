//
//  ObservationStatusOkTableViewCell.m
//  MAGE
//
//  Created by William Newman on 4/14/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

@import HexColors;

#import "ObservationStatusOkTableViewCell.h"
#import "NSDate+display.h"
#import "Theme+UIResponder.h"

@implementation ObservationStatusOkTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    self.statusLabel.textColor = [UIColor colorWithHexString:@"00C853" alpha:1.0];
}

- (void) configureCellForObservation: (Observation *) observation withForms:(NSArray *)forms {
    self.statusLabel.text = observation.lastModified ? [NSString stringWithFormat:@"Pushed on %@", [observation.lastModified formattedDisplayDate]] : @"Pushed";
    [self registerForThemeChanges];
}

@end
