//
//  LocationAnnotation.m
//  Mage
//
//

@import DateTools;

#import "LocationAnnotation.h"
#import "User.h"
#import "MKAnnotationView+PersonIcon.h"
#import "WKBGeometryUtils.h"
#import "Theme+UIResponder.h"

@implementation LocationAnnotation

-(id) initWithLocation:(Location *) location {
	if ((self = [super init])) {
		_location = location;
		
        WKBPoint *centroid = [WKBGeometryUtils centroidOfGeometry:location.geometry];
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]);
        [self setCoordinate:coordinate];
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
        rightButton.tintColor = [UIColor mageBlue];
        annotationView.rightCalloutAccessoryView = rightButton;
    } else {
        annotationView.annotation = self;
    }
    
    [annotationView setImageForUser:self.location.user];
    
    annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f) + 7);
    return annotationView;
}

@end
