//
//  Geometry.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/7/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Geometry : NSObject <NSCoding>

typedef NS_ENUM(NSInteger, GeometryType) {
    POINT
};

- (GeometryType) getGeometryType;

@end
