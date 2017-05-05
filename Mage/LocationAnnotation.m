//
//  LocationAnnotation.m
//  Mage
//
//

#import "LocationAnnotation.h"
#import "GeoPoint.h"
#import "User.h"
#import "NSDate+DateTools.h"
#import "MKAnnotationView+PersonIcon.h"

@implementation LocationAnnotation

-(id) initWithLocation:(Location *) location {
	if ((self = [super init])) {
		_location = location;
		
        [self setCoordinate:((GeoPoint *) location.geometry).location.coordinate];
		_timestamp = location.timestamp;
		
		User *user = location.user;
        [self setTitle:user.name];
        [self setSubtitle:location.timestamp.timeAgoSinceNow];
    }
		
    return self;
}

-(void) setLocation:(Location *)location {
    _location = location;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView; {
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"locationAnnotation"];
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"locationAnnotation"];
        annotationView.enabled = YES;
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        rightButton.tintColor = [UIColor colorWithRed:17.0/255.0 green:84.0/255.0 blue:164.0/255.0 alpha:1.0];
        annotationView.rightCalloutAccessoryView = rightButton;
    } else {
        annotationView.annotation = self;
    }
    
    [annotationView setImageForUser:self.location.user];
    
    annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f) + 7);
    return annotationView;
}

@end
