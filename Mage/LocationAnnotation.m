//
//  LocationAnnotation.m
//  Mage
//
//  Created by Billy Newman on 6/24/14.
//

#import "LocationAnnotation.h"
#import "GeoPoint.h"
#import "User+helper.h"
#import "NSDate+DateTools.h"
#import "MKAnnotationView+PersonIcon.h"

@implementation LocationAnnotation

-(id) initWithLocation:(Location *) location {
	if ((self = [super init])) {
		_location = location;
		
        _coordinate = ((GeoPoint *) location.geometry).location.coordinate;
		_timestamp = location.timestamp;
		
		User *user = location.user;
		_title = user.name != nil ? user.name : user.username;
		_subtitle = location.timestamp.timeAgoSinceNow;
    }
		
    return self;
}

-(void) setCoordinate:(CLLocationCoordinate2D) coordinate {
	_coordinate = coordinate;
}

-(void) setLocation:(Location *)location {
    _location = location;
}

-(void) setSubtitle:(NSString *)subtitle {
    _subtitle = subtitle;
}


- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView; {
    MKAnnotationView *annotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"locationAnnotation"];
    if (annotationView == nil) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"locationAnnotation"];
        annotationView.enabled = YES;
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
        rightButton.tintColor = [UIColor colorWithRed:17.0/255.0 green:84.0/255.0 blue:164.0/255.0 alpha:1.0];
        [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
        annotationView.rightCalloutAccessoryView = rightButton;
    } else {
        annotationView.annotation = self;
    }
    
    [annotationView setImageForUser:self.location.user];
    
    annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f) + 7);
    return annotationView;
}

@end
