//
//  Geometry.m
//  mage-ios-sdk
//
//

#import "Geometry.h"

@implementation Geometry

- (GeometryType) getGeometryType {
    return POINT;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
}

- (id) initWithCoder:(NSCoder *)encoder {
    return [self init];
}

@end
