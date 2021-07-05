//
//  LocationAnnotation.m
//  Mage
//
//

@import DateTools;

#import "LocationAnnotation.h"
#import "User.h"
#import "MKAnnotationView+PersonIcon.h"
#import "SFGeometryUtils.h"

@implementation LocationAnnotation

-(id) initWithLocation:(Location *) location {
	if ((self = [super init])) {
        _location = [[CLLocation alloc] initWithCoordinate:location.location.coordinate
                                                  altitude:[[location.properties valueForKey:@"altitude"] doubleValue]
                                        horizontalAccuracy:[[location.properties valueForKey:@"accuracy"] doubleValue]
                                          verticalAccuracy:[[location.properties valueForKey:@"verticalAccuracy"] doubleValue]
                                                    course:[[location.properties valueForKey:@"course"] doubleValue]
                                                     speed:[[location.properties valueForKey:@"speed"] doubleValue]
                                                 timestamp:location.timestamp];
        
        [self setCoordinate:_location.coordinate];
        
		_timestamp = location.timestamp;
		
        _user = location.user;
        [self setTitle:location.user.name];
        [self setSubtitle:location.timestamp.timeAgoSinceNow];
    }
		
    return self;
}

-(id) initWithGPSLocation: (GPSLocation *) gpsLocation user: (User *) user {
    if ((self = [super init])) {
        SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:[gpsLocation getGeometry]];
        _location = [[CLLocation alloc] initWithCoordinate:(CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]))
                                                  altitude:[[gpsLocation.properties valueForKey:@"altitude"] doubleValue]
                                        horizontalAccuracy:[[gpsLocation.properties valueForKey:@"accuracy"] doubleValue]
                                          verticalAccuracy:[[gpsLocation.properties valueForKey:@"verticalAccuracy"] doubleValue]
                                                    course:[[gpsLocation.properties valueForKey:@"course"] doubleValue]
                                                     speed:[[gpsLocation.properties valueForKey:@"speed"] doubleValue]
                                                 timestamp:gpsLocation.timestamp];
        
        [self setCoordinate:_location.coordinate];
        
        _timestamp = gpsLocation.timestamp;
        
        _user = user;
        [self setTitle:user.name];
        [self setSubtitle:gpsLocation.timestamp.timeAgoSinceNow];
    }
    
    return self;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView; {
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"locationAnnotation"];
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"locationAnnotation"];
        annotationView.enabled = YES;
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
//        rightButton.tintColor = [UIColor mageBlue];
        annotationView.rightCalloutAccessoryView = rightButton;
    } else {
        annotationView.annotation = self;
    }
    
    [annotationView setImageForUser:self.user];
    
    annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f) + 7);
    return annotationView;
}

@end
