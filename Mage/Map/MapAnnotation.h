//
//  MapAnnotation.h
//  MAGE
//
//  Created by Brian Osborn on 5/3/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AnnotationDragCallback.h"
@import MaterialComponents;

/**
 *  Common map annotation
 */
@interface MapAnnotation : NSObject <MKAnnotation>

@property (nonatomic) NSUInteger id;
@property (nonatomic, strong) MKAnnotationView * view;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

-(id)init;
-(NSNumber *) getIdAsNumber;
-(MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView scheme: (id<MDCContainerScheming>) scheme;
-(MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView withDragCallback: (NSObject<AnnotationDragCallback> *) dragCallback scheme: (id<MDCContainerScheming>) scheme;
-(void) hidden: (BOOL) hidden;

@end
