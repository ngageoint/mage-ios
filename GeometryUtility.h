//
//  GeometryUtility.h
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/25/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGeometry.h"
#import "SFPoint.h"

@interface GeometryUtility : NSObject

+(SFGeometry *) toGeometryFromGeometryData: (NSData *) geometryData;

+(NSData *) toGeometryDataFromGeometry: (SFGeometry *) geometry;

+(SFPoint *) centroidOfGeometry: (SFGeometry *) geometry;

@end
