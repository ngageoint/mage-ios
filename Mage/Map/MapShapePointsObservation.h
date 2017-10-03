//
//  MapShapePointsObservation.h
//  MAGE
//
//  Created by Brian Osborn on 5/23/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapShapeObservation.h"
#import "GPKGMapShapePoints.h"

@interface MapShapePointsObservation : MapShapeObservation

/**
 *  Initializer
 *
 *  @param observation  observation
 *  @param shapePoints  map shape points
 *
 *  @return new instance
 */
-(instancetype) initWithObservation: (Observation *) observation andShapePoints: (GPKGMapShapePoints *) shapePoints;

-(GPKGMapShapePoints *) shapePoints;

@end
