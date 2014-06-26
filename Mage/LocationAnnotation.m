//
//  LocationAnnotation.m
//  Mage
//
//  Created by Billy Newman on 6/24/14.
//

#import "LocationAnnotation.h"
#import "GeoPoint.h"

@implementation LocationAnnotation

-(id) initWithLocation:(Location *) location {
	if ((self = [super init])) {
        _coordinate = ((GeoPoint *) location.geometry).location.coordinate;
		_timestamp = location.timestamp;
    }
		
    return self;
}

-(NSString *) title {
	return _username ? _username : @"Uknown";
}

-(NSString *) subtitle {
	return _name ? _name : nil;
}

-(void) setCoordinate:(CLLocationCoordinate2D) coordinate {
	_coordinate = coordinate;
}

//- (MKMapItem *) mapItem {
//    NSDictionary *addressDict = @{(NSString*)kABPersonAddressStreetKey : _address};
//	
//    MKPlacemark *placemark = [[MKPlacemark alloc]
//                              initWithCoordinate:self.coordinate
//                              addressDictionary:addressDict];
//	
//    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
//    mapItem.name = self.title;
//	
//    return mapItem;
//}

@end
