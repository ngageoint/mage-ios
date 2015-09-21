//
//  GPSLocationAnnotation.m
//  MAGE
//
//

#import "GPSLocationAnnotation.h"
#import <GeoPoint.h>
#import <NSDate+DateTools.h>

@implementation GPSLocationAnnotation

-(id) initWithGPSLocation: (GPSLocation *) gpsLocation andUser: (User *) user {
    if ((self = [super init])) {
        _gpsLocation = gpsLocation;
        GeoPoint *point = (GeoPoint *)gpsLocation.geometry;
        _coordinate = point.location.coordinate;
        _timestamp = gpsLocation.timestamp;
        
        _title = user.name != nil ? user.name : user.username;
        _subtitle = gpsLocation.timestamp.timeAgoSinceNow;
        _user = user;
    }
    
    return self;
}

-(void) setCoordinate:(CLLocationCoordinate2D) coordinate {
    _coordinate = coordinate;
}

-(void) setGPSLocation:(GPSLocation *)location {
    self.gpsLocation = location;
}
@end
