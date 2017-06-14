//
//  ObservationStatusOkTableViewCell.m
//  MAGE
//
//  Created by William Newman on 4/14/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationStatusOkTableViewCell.h"
#import "NSDate+display.h"

@implementation ObservationStatusOkTableViewCell

- (void) configureCellForObservation: (Observation *) observation {
    self.statusLabel.text = observation.lastModified ? [NSString stringWithFormat:@"Pushed on %@", [observation.lastModified formattedDisplayDate]] : @"Pushed";
}

@end
