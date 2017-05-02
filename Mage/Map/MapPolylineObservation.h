//
//  MapPolylineObservation.h
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapShapeObservation.h"

@interface MapPolylineObservation : MapShapeObservation

/**
 *  Initializer
 *
 *  @param observation  observation
 *  @param shape        map shape
 *
 *  @return new instance
 */
-(instancetype) initWithObservation: (Observation *) observation andMapShape: (GPKGMapShape *) shape;

@end
