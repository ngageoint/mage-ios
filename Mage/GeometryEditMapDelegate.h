//
//  GeometryEditMapDelegate.h
//  MAGE
//
//  Created by Dan Barela on 8/21/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "AnnotationDragCallback.h"

@protocol EditableMapAnnotationDelegate <NSObject>

- (void) mapView: (MKMapView *) mapView didSelectAnnotationView: (MKAnnotationView *) view;
- (void) mapView: (MKMapView *) mapView didDeselectAnnotationView: (MKAnnotationView *) view;
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *) annotationView didChangeDragState:(MKAnnotationViewDragState) newState fromOldState:(MKAnnotationViewDragState) oldState;

@end

@interface GeometryEditMapDelegate : NSObject <MKMapViewDelegate>

- (instancetype) initWithDragCallback: (id<AnnotationDragCallback>) dragCallback andEditDelegate: (id<EditableMapAnnotationDelegate>) editDelegate ;

@end
