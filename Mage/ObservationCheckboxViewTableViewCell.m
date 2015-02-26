//
//  ObservationCheckboxViewTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 2/20/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationCheckboxViewTableViewCell.h"

@implementation ObservationCheckboxViewTableViewCell

- (void) populateCellWithKey:(id) key andValue:(id) value {
    [self.checkboxSwitch setOn:[value boolValue]];
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end
