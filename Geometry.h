//
//  Geometry.h
//  mage-ios-sdk
//
//

#import <Foundation/Foundation.h>

@interface Geometry : NSObject <NSCoding>

typedef NS_ENUM(NSInteger, GeometryType) {
    POINT
};

- (GeometryType) getGeometryType;

@end
