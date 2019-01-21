//
//  GPSLocationAnnotation.m
//  MAGE
//
//

#import "GPSLocationAnnotation.h"
#import "MKAnnotationView+PersonIcon.h"
#import "SFGeometry.h"
#import "SFGeometryUtils.h"

@implementation GPSLocationAnnotation

-(id) initWithGPSLocation: (GPSLocation *) gpsLocation andUser: (User *) user {
    if ((self = [super init])) {
        _gpsLocation = gpsLocation;
        SFGeometry *geometry = (SFGeometry *)gpsLocation.geometry;
        SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:geometry];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]);
        [self setCoordinate:location];
        _timestamp = gpsLocation.timestamp;
        
        [self setTitle:user.name];
        [self setSubtitle:gpsLocation.timestamp.timeAgoSinceNow];
        _user = user;
    }
    
    return self;
}

-(void) setGPSLocation:(GPSLocation *)location {
    self.gpsLocation = location;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView {
    
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"gpsLocationAnnotation"];
    
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"gpsLocationAnnotation"];
        annotationView.enabled = YES;
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        annotationView.rightCalloutAccessoryView = rightButton;
        annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f));
    } else {
        annotationView.annotation = self;
    }
    
    [annotationView setImageForUser:self.user];
    
    return annotationView;
}

@end
