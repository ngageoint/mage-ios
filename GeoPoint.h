//
//  Point.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/7/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Geometry.h"
#import <CoreLocation/CoreLocation.h>

@interface GeoPoint : Geometry

@property(strong) CLLocation *location;
- (id)initWithLocation: (CLLocation *) location;

@end
