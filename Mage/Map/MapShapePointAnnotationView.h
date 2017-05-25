//
//  MapShapePointAnnotationView.h
//  MAGE
//
//  Created by Brian Osborn on 5/24/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "AnnotationDragCallback.h"

@interface MapShapePointAnnotationView : MKAnnotationView

- (instancetype)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier andMapView: (MKMapView *) mapView andDragCallback: (NSObject<AnnotationDragCallback> *) dragCallback;

@end
