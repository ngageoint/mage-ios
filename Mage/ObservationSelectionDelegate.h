//
//  ObservationItemSelectionDelegate.h
//  MAGE
//
//  Created by William Newman on 9/24/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Observation+helper.h"

@protocol ObservationSelectionDelegate <NSObject>

@required
    - (void) selectedObservation:(Observation *) observation;
    - (void) selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region;
- (void) observationDetailSelected: (Observation *) observation;

@end
