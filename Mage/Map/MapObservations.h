//
//  MapObservations.h
//  MAGE
//
//  Created by Brian Osborn on 5/2/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapObservation.h"
#import "MapAnnotation.h"
#import "MapShapeObservation.h"
#import "MapAnnotationObservation.h"

@interface MapObservationsEnumerator : NSObject <NSFastEnumeration>

-(instancetype) initWithType: (Class) type andObservations: (NSArray<MapObservation *> *) observations;

@end

@interface MapAnnotationObservationEnumerator : MapObservationsEnumerator

-(instancetype) initWithObservations: (NSArray<MapObservation *> *) observations;

@end

@interface MapShapeObservationEnumerator : MapObservationsEnumerator

-(instancetype) initWithObservations: (NSArray<MapObservation *> *) observations;

@end

@interface MapObservations : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSManagedObjectID *, MapObservation *> *observationIds;

/**
 *  Initializer
 *
 *  @param mapView    map view
 *  @return new instance
 */
-(instancetype) initWithMapView: (MKMapView *) mapView;

/**
 * Add a map observation
 *
 * @param mapObservation map observation
 */
-(void) addMapObservation: (MapObservation *) mapObservation;

/**
 * Get a map observation by id
 *
 * @param observationId observation id
 * @return map observation
 */
-(MapObservation *) observationOfId: (NSManagedObjectID *) observationId;

/**
 * Get an observation by annotation id, either an annotation observation or a selected shape marker
 *
 * @param annotationId annotation id
 * @return observation
 */
-(Observation *) observationOfAnnotationId: (NSUInteger) annotationId;

/**
 * Get an observation by annotation id number, either an annotation observation or a selected shape marker
 *
 * @param annotationId annotation id
 * @return observation
 */
-(Observation *) observationOfAnnotationIdNumber: (NSNumber *) annotationId;

/**
 * Check if the map observation is an annotation
 *
 * @param mapObservation map observation
 * @return true if a marker annotation
 */
+(BOOL) isAnnotation: (MapObservation *) mapObservation;

/**
 * Check if the map observation is a shape
 *
 * @param mapObservation map observation
 * @return true if a shape observation
 */
+(BOOL) isShape: (MapObservation *) mapObservation;

/**
 * Remove the map observation
 *
 * @param observationId observation id
 * @return removed map observation
 */
-(MapObservation *) removeById: (NSManagedObjectID *) observationId;

/**
 * Remove observations from the map that are not in the array
 *
 * @param idArray observations to keep
 */
- (void) removeObservationsNotInArray: (NSArray<NSManagedObjectID *> *) idArray;

/**
 * Set the visibility on all map observations
 *
 * @param visible visible flag
 */
-(void) hidden: (BOOL) hidden;

/**
 * Set the temporary annotation for a selected shape
 *
 * @param shapeAnnotation  shape annotation
 * @param shapeObservation shape observation
 */
-(void) setShapeAnnotation: (MapAnnotation *) shapeAnnotation withShapeObservation: (MapShapeObservation *) shapeObservation;

/**
 * If one exists, select the shape annotation
 */
-(void) selectShapeAnnotation;

/**
 * Clear the shape annotation from the map
 */
-(void) clearShapeAnnotation;

/**
 * Clear all map observations from the map and collections
 */
-(void) clear;

/**
 * Get the clicked shape from the click location
 *
 * @param location click location
 * @return map shape observation
 */
-(MapShapeObservation *) clickedShapeAtLocation: (CLLocationCoordinate2D) location;

/**
 * Get all annotations as a fast enumeration
 *
 * @return iterable markers
 */
-(MapAnnotationObservationEnumerator *) annotations;

/**
 * Get all shapes as a fast enumeration
 *
 * @return iterable shapes
 */
-(MapShapeObservationEnumerator *) shapes;

@end
