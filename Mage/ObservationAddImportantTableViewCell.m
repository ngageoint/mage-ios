//
//  ObservationAddImportantTableViewCell.m
//  MAGE
//
//  Created by William Newman on 10/27/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationAddImportantTableViewCell.h"
#import "User.h"

@implementation ObservationAddImportantTableViewCell

- (IBAction) onUpdateImportantTapped:(id)sender {
    if (self.observationImportantDelegate) {
        [self.observationImportantDelegate flagObservationImportant];
    }
}

@end
