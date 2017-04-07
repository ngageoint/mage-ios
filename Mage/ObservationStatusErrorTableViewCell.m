//
//  ObservationStatusErrorTableViewCell.m
//  MAGE
//
//  Created by William Newman on 4/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationStatusErrorTableViewCell.h"

@implementation ObservationStatusErrorTableViewCell

- (void) configureCellForObservation: (Observation *) observation {
    self.errorLabel.text = [observation errorMessage];
}

@end
