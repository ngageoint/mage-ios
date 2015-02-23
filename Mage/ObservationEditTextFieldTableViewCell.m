//
//  ObservationEditTextFieldTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 9/25/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTextFieldTableViewCell.h"

@implementation ObservationEditTextFieldTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    id value = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    
    if (value != nil) {
        [self.textField setText:value];
    } else {
        [self.textField setText:[field objectForKey:@"value"]];
    }
    
    [self.keyLabel setText:[field objectForKey:@"title"]];
}

@end
