//
//  MapObservationManager.h
//  MAGE
//
//  Created by Brian Osborn on 5/2/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapObservation.h"
#import "MapAnnotation.h"

/**
 * Handles adding Observations to the map as markers or shapes
 *
 * @author osbornb
 */
@interface MapObservationManager : NSObject

/**
 *  Initializer
 *
 *  @param mapView  map view
 *
 *  @return new instance
 */
-(instancetype) initWithMapView: (MKMapView *) mapView;

/**
 * Add an observation to the map as a marker or shape
 *
 * @param observation observation
 * @return map observation
 */
-(MapObservation *) addToMapWithObservation: (Observation *) observation;

/**
 * Add an observation to the map as a marker or shape
 *
 * @param observation observation
 * @param hidden     hidden state
 * @return map observation
 */
-(MapObservation *) addToMapWithObservation: (Observation *) observation andHidden: (BOOL) hidden;

/**
 * Add a shape marker to the map at the location.  A shape marker is a transparent icon for allowing shape info windows.
 *
 * @param latLng  lat lng location
 * @param observation observation
 * @param visible visible state
 * @return shape marker
 */
-(MapAnnotation *) addShapeAnnotationAtLocation: (CLLocationCoordinate2D) location forObservation: (Observation *) observation andHidden: (BOOL) hidden;

@end
