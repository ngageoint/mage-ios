//
//  ObservationEditGeometryTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 9/25/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditGeometryTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import "Observation+helper.h"

@implementation ObservationEditGeometryTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    
    // special case if it is the actuial observation geometry and not a field
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.geoPoint = (GeoPoint *)[observation geometry];
    } else {
        self.geoPoint = (GeoPoint *)[observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    }

    [self.latitude setText:[NSString stringWithFormat:@"%.5f",self.geoPoint.location.coordinate.latitude]];
    [self.longitude setText:[NSString stringWithFormat:@"%.5f",self.geoPoint.location.coordinate.longitude]];
    [self.keyLabel setText:[field objectForKey:@"title"]];
}

@end
