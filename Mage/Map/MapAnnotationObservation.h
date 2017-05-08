//
//  MapAnnotationObservation.h
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapObservation.h"
#import "ObservationAnnotation.h"
#import "ObservationAnnotationView.h"

/**
 * Observation represented by a single Annotation on the map
 *
 * @author osbornb
 */
@interface MapAnnotationObservation : MapObservation

/**
 * Annotation view
 */
@property (nonatomic, strong) ObservationAnnotationView *view;

/**
 *  Initializer
 *
 *  @param observation  observation
 *  @param annotation   annotation
 *
 *  @return new instance
 */
-(instancetype) initWithObservation: (Observation *) observation andAnnotation: (ObservationAnnotation *) annotation;

/**
 * Get the observation annotation
 *
 * @return observation annotation
 */
-(ObservationAnnotation *) annotation;

@end
