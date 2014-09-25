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
    NSLog(@"field name: %@, observation properties for field name: %@", (NSString *)[field objectForKey:@"name"], [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]]);
    id value = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    [self.textField setText:value];
    [self.keyLabel setText:[field objectForKey:@"title"]];
}

@end
