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
 * @param location    location
 * @param tolerance line width tolerance
 * @param mapView map view
 * @return true if point is on shape
 */
-(BOOL) isOnShapeAtLocation: (CLLocationCoordinate2D) location withTolerance: (double) tolerance andMapView: (MKMapView *) mapView;

@end
