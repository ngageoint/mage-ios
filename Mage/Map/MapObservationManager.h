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
@import SimpleFeatures;

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
 * @param animateDrop should animate or not
 * @return map observation
 */
-(MapObservation *) addToMapWithObservation:(Observation *)observation andAnimateDrop: (BOOL) animateDrop;

/**
 * Add an observation to the map as an annotation or shape
 *
 * @param observation observation
 * @param hidden     hidden state
 * @return map observation
 */
-(MapObservation *) addToMapWithObservation: (Observation *) observation andHidden: (BOOL) hidden;

/**
 * Add an observation using the geometry to the map as an annotation or shape
 *
 * @param observation observation
 * @param geometry    geometry
 * @return map observation
 */
-(MapObservation *) addToMapWithObservation: (Observation *) observation withGeometry: (SFGeometry *) geometry;

/**
 * Add an observation using the geometry to the map as an annotation or shape
 *
 * @param observation observation
 * @param geometry    geometry
 * @param hidden     hidden state
 * @param animateDrop should animate or not
 * @return map observation
 */
-(MapObservation *) addToMapWithObservation: (Observation *) observation withGeometry: (SFGeometry *) geometry andHidden: (BOOL) hidden andAnimateDrop: (BOOL) animateDrop;

/**
 * Add a shape annotation to the map at the location.  A shape annotation is a transparent icon for shape info windows.
 *
 * @param location  coordinate location
 * @param observation observation
 * @param hidden hidden state
 * @return map annotation
 */
-(MapAnnotation *) addShapeAnnotationAtLocation: (CLLocationCoordinate2D) location forObservation: (Observation *) observation andHidden: (BOOL) hidden;

@end
