//
//  MapObservation.h
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Observation.h"
@import MapKit;

/**
 * Observation that has been added to the map
 *
 * @author osbornb
 */
@interface MapObservation : NSObject

/**
 *  Initializer
 *
 *  @param observation  observation
 *
 *  @return new instance
 */
-(instancetype) initWithObservation: (Observation *) observation;

/**
 * Get the observation
 *
 * @return observation
 */
-(Observation *) observation;

/**
 * Remove the observation from the map
 *
 * @param mapView map view
 */
-(void) removeFromMapView: (MKMapView *) mapView;

/**
 * Set the observation visibility on the map
 *
 * @param hidden hidden flag
 * @param mapView map view
 */
-(void) hidden: (BOOL) hidden fromMapView: (MKMapView *) mapView;

/**
 * Get the view region of the map view for the observation
 *
 * @param mapView map view
 *
 * @return coordinate region
 */
-(MKCoordinateRegion) viewRegionOfMapView: (MKMapView *) mapView;

@end
