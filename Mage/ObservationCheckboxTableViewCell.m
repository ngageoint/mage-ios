//
//  ObservationCheckboxTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 9/25/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationCheckboxTableViewCell.h"

@implementation ObservationCheckboxTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    NSLog(@"field name: %@, observation properties for field name: %@", (NSString *)[field objectForKey:@"name"], [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]]);
    id value = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    [self.checkboxSwitch setOn:[value boolValue]];
    [self.keyLabel setText:[field objectForKey:@"title"]];
}

- (CGFloat) getCellHeightForValue: (id) value {
    NSLog([NSString stringWithFormat:@"CB cell height bounds: %f", self.bounds.size.height]);
    NSLog([NSString stringWithFormat:@"CB cell height frame: %f", self.contentView.frame.size.height]);
    return self.bounds.size.height;
}

@end
