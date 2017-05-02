//
//  MapShapeObservation.h
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapObservation.h"
#import "GPKGMapShape.h"

/**
 * Observation represented by a shape on the map
 *
 * @author osbornb
 */
@interface MapShapeObservation : MapObservation

/**
 * Create a map shape observation
 *
 * @param observation observation
 * @param shape       map shape
 * @return map shape observation
 */
+(MapShapeObservation *) createWithObservation: (Observation *) observation andMapShape: (GPKGMapShape *) shape;

/**
 *  Initializer
 *
 *  @param observation  observation
 *  @param shape        map shape
 *
 *  @return new instance
 */
-(instancetype) initWithObservation: (Observation *) observation andMapShape: (GPKGMapShape *) shape;

/**
 * Get the shape
 *
 * @return shape
 */
-(GPKGMapShape *) shape;

/**
 * Determine if the point is on the shape, either on a polygon or within the distance tolerance of a line
 *
 * @param latLng    point
 * @param tolerance line tolerance
 * @return true if point is on shape
 */
-(BOOL) isOnShapeWithLocation: (CLLocation *) location andTolerance: (double) tolerance;

@end
