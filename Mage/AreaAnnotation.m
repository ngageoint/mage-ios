//
//  AreaAnnotation.m
//  MAGE
//
//  Created by Dan Barela on 2/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AreaAnnotation.h"

@implementation AreaAnnotation

-(void) setCoordinate:(CLLocationCoordinate2D) coordinate {
    _coordinate = coordinate;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView {
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"areaAnnotation"];
    
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"areaAnnotation"];
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
    } else {
        annotationView.annotation = self;
    }
    return annotationView;

}

- (void) setTitle:(NSString *)title {
    _title = title;
}

@end
