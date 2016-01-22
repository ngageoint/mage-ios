//
//  ObservationAnnotation.m
//  Mage
//
//

#import "ObservationAnnotation.h"
#import "GeoPoint.h"
#import "NSDate+DateTools.h"
#import "ObservationImage.h"

@implementation ObservationAnnotation

-(id) initWithObservation:(Observation *) observation {
	if ((self = [super init])) {
        _coordinate = ((GeoPoint *) observation.geometry).location.coordinate;
		
		_observation = observation;
		_title = [observation.properties objectForKey:@"type"];
        if (_title == nil) {
            _title = @"Observation";
        }
		_subtitle = observation.timestamp.timeAgoSinceNow;
    }
    [self setAccessibilityLabel:@"Observation Annotation"];
    [self setAccessibilityValue:@"Observation Annotation"];
    return self;
}

-(void) setCoordinate:(CLLocationCoordinate2D) coordinate {
	_coordinate = coordinate;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView {
    UIImage *image = [ObservationImage imageForObservation:self.observation inMapView:mapView];
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:[image accessibilityIdentifier]];
    
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:[image accessibilityIdentifier]];
        annotationView.enabled = YES;
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        rightButton.tintColor = [UIColor colorWithRed:17.0/255.0 green:84.0/255.0 blue:164.0/255.0 alpha:1.0];
        annotationView.rightCalloutAccessoryView = rightButton;
        annotationView.image = image;
        annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f));
    } else {
        annotationView.annotation = self;
    }
    [annotationView setAccessibilityLabel:@"Observation"];
    [annotationView setAccessibilityValue:@"Observation"];
    return annotationView;
}

@end
