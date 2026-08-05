//
//  LocationAnnotation.m
//  Mage
//
//

@import DateTools;
@import MaterialComponents;
@import Persistence;

#import "LocationAnnotation.h"
@import SimpleFeatures;
#import <PureLayout.h>
#import "MAGE-Swift.h"

@implementation LocationAnnotation

-(id) initWithLocation:(NSManagedObject *) location {
	if ((self = [super init])) {
        Location* strongLocation = (Location *)location;
        _location = strongLocation.location;
        
        [self setCoordinate:_location.coordinate];
        
		_timestamp = strongLocation.timestamp;
		
        _user = strongLocation.user;
        [self setTitle:strongLocation.user.name];
        [self setSubtitle:strongLocation.timestamp.timeAgoSinceNow];
    }
		
    return self;
}

-(id) initWithGPSLocation: (NSManagedObject *) gpsLocation user: (User *) user {
    if ((self = [super init])) {
        GPSLocation *strongGpsLocation = (GPSLocation *)gpsLocation;
        SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:strongGpsLocation.geometry];
        // TODO: when this is swift, use user.location
        _location = [[CLLocation alloc] initWithCoordinate:(CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]))
                                                  altitude:[[strongGpsLocation.properties valueForKey:@"altitude"] doubleValue]
                                        horizontalAccuracy:[[strongGpsLocation.properties valueForKey:@"accuracy"] doubleValue]
                                          verticalAccuracy:[[strongGpsLocation.properties valueForKey:@"verticalAccuracy"] doubleValue]
                                                    course:[[strongGpsLocation.properties valueForKey:@"course"] doubleValue]
                                                     speed:[[strongGpsLocation.properties valueForKey:@"speed"] doubleValue]
                                                 timestamp:strongGpsLocation.timestamp];
        
        [self setCoordinate:_location.coordinate];
        
        _timestamp = strongGpsLocation.timestamp;
        
        _user = user;
        [self setTitle:user.name];
        [self setSubtitle:strongGpsLocation.timestamp.timeAgoSinceNow];
    }
    
    return self;
}

- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView scheme: (id<MDCContainerScheming>) scheme {
    MKAnnotationView *annotationView = nil;
    User *user = (User *)self.user;
    if (user.iconColor || user.iconUrl == nil) {
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
