//
//  LocationAnnotation.m
//  Mage
//
//

@import DateTools;
@import MaterialComponents;

#import "LocationAnnotation.h"
#import "SFGeometryUtils.h"
#import <PureLayout.h>
#import "MAGE-Swift.h"

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
        SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:gpsLocation.geometry];
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

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView scheme: (id<MDCContainerScheming>) scheme {
    MKAnnotationView *annotationView = nil;
    if (self.user.iconColor || self.user.iconUrl == nil) {
        PersonAnnotationView *personAnnotationView = (PersonAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"locationAnnotation"];
        if (personAnnotationView == nil) {
            personAnnotationView = [[PersonAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"locationAnnotation"];
            personAnnotationView.scheme = scheme;
            personAnnotationView.enabled = YES;
        } else {
            personAnnotationView.annotation = self;
        }
        personAnnotationView.titleVisibility = MKFeatureVisibilityHidden;
        annotationView = personAnnotationView;
    } else {
        annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"userIconAnnotation"];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"userIconAnnotation"];
            annotationView.enabled = YES;
        } else {
            annotationView.annotation = self;
        }

        [PersonAnnotationView setImageForAnnotationWithAnnotation:annotationView user:self.user];
    }
    annotationView.displayPriority = MKFeatureDisplayPriorityRequired;
    annotationView.collisionMode = MKAnnotationViewCollisionModeNone;
    self.view = annotationView;
    return annotationView;
}

@end
