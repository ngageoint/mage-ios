//
//  GeometryUtility.h
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/25/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKBGeometry.h"

@interface GeometryUtility : NSObject

+(WKBGeometry *) toGeometryFromGeometryData: (NSData *) geometryData;

+(NSData *) toGeometryDataFromGeometry: (WKBGeometry *) geometry;

@end
