//
//  Point.h
//  mage-ios-sdk
//
//

#import "Geometry.h"
#import <CoreLocation/CoreLocation.h>

@interface GeoPoint : Geometry

@property(strong) CLLocation *location;

- (id)initWithLocation: (CLLocation *) location;

@end
