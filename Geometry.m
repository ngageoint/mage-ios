//
//  Geometry.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/7/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
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
