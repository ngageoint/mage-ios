//
//  Point.m
//  mage-ios-sdk
//
//

#import "GeoPoint.h"
#define locationKey @"location"

@implementation GeoPoint : Geometry

- (id)initWithLocation:(CLLocation *)location {
    if ((self = [super init])) {
        _location = [location copy];
    }
    return self;
}

- (GeometryType) getGeometryType {
    return POINT;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_location forKey:locationKey];
}

- (id) initWithCoder:(NSCoder *)decoder {
    CLLocation *location = [decoder decodeObjectForKey:locationKey];
    return [self initWithLocation:location];
}

@end
