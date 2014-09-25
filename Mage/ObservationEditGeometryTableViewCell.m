//
//  ObservationEditGeometryTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 9/25/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditGeometryTableViewCell.h"

@implementation ObservationEditGeometryTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    
    id value = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    //
    //    NSDate *date = [[self dateParseFormatter] dateFromString:[observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]]];
    //    [self.valueLabel setText:[[self dateDisplayFormatter] stringFromDate:date]];
    [self.keyLabel setText:[field objectForKey:@"title"]];
}

@end
