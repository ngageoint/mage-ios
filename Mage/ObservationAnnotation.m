//
//  ObservationAnnotation.m
//  Mage
//
//  Created by Dan Barela on 6/26/14.
//

#import "ObservationAnnotation.h"
#import "GeoPoint.h"
#import "NSDate+DateTools.h"

@implementation ObservationAnnotation

-(id) initWithObservation:(Observation *) observation {
	if ((self = [super init])) {
        _coordinate = ((GeoPoint *) observation.geometry).location.coordinate;
		
		_observation = observation;
		_title = [observation.properties objectForKey:@"type"];
		_subtitle = observation.timestamp.timeAgoSinceNow;
    }

    return self;
}

-(void) setCoordinate:(CLLocationCoordinate2D) coordinate {
	_coordinate = coordinate;
}

@end
