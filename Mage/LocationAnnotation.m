//
//  LocationAnnotation.m
//  Mage
//
//  Created by Billy Newman on 6/24/14.
//

#import "LocationAnnotation.h"
#import "GeoPoint.h"
#import "User+helper.h"

@implementation LocationAnnotation

-(id) initWithLocation:(Location *) location {
	if ((self = [super init])) {
		_location = location;
		
        _coordinate = ((GeoPoint *) location.geometry).location.coordinate;
		_timestamp = location.timestamp;
		
		User *user = location.user;
		_title = user.name;
		_subtitle = user.username;
    }
		
    return self;
}

-(void) setCoordinate:(CLLocationCoordinate2D) coordinate {
	_coordinate = coordinate;
}

@end
