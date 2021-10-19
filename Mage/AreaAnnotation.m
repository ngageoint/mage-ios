//
//  AreaAnnotation.m
//  MAGE
//
//

#import "AreaAnnotation.h"

@implementation AreaAnnotation

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView scheme: (id<MDCContainerScheming>) scheme {
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

@end
