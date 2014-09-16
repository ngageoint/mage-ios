//
//  MapDelegate.m
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapDelegate.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import "PersonImage.h"
#import "ObservationImage.h"

@implementation MapDelegate

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
    if ([annotation isKindOfClass:[LocationAnnotation class]]) {
		LocationAnnotation *locationAnnotation = annotation;
		UIImage *image = [PersonImage imageForLocation:locationAnnotation.location];
        MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:[image accessibilityIdentifier]];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[image accessibilityIdentifier]];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = image;
			
			UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
			[rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
			annotationView.rightCalloutAccessoryView = rightButton;
		} else {
            annotationView.annotation = annotation;
        }
		
        return annotationView;
    } else if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = annotation;
        UIImage *image = [ObservationImage imageForObservation:observationAnnotation.observation scaledToWidth:[NSNumber numberWithFloat:35]];
        MKAnnotationView *annotationView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:[image accessibilityIdentifier]];
        
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[image accessibilityIdentifier]];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
			
			UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
			[rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
			annotationView.rightCalloutAccessoryView = rightButton;
            annotationView.image = image;
		} else {
            annotationView.annotation = annotation;
        }
		
        return annotationView;
    }
	
    return nil;
}

// TODO once we get a 'me' page we will segue to that page from here
//- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
//
//	if (view == [_mapView viewForAnnotation:_mapView.userLocation]) {
//		UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
//		[rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
//		view.rightCalloutAccessoryView = rightButton;
//	}
//}

- (void) mapView:(MKMapView *) mapView annotationView:(MKAnnotationView *) view calloutAccessoryControlTapped:(UIControl *) control {
	if ([view.annotation isKindOfClass:[LocationAnnotation class]] || view.annotation == mapView.userLocation) {
		[self.viewController performSegueWithIdentifier:@"DisplayPersonSegue" sender:view];
	} else if ([view.annotation isKindOfClass:[ObservationAnnotation class]]) {
		[self.viewController performSegueWithIdentifier:@"DisplayObservationSegue" sender:view];
	}
}


@end
