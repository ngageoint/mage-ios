//
//  CacheOverlayTypes.h
//  MAGE
//
//  Created by Brian Osborn on 12/17/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Enumeration of cache overlay types
 */
enum CacheOverlayType{
    XYZ_DIRECTORY,
    GEOPACKAGE,
    GEOPACKAGE_TILE_TABLE,
    GEOPACKAGE_FEATURE_TABLE
};

@interface CacheOverlayTypes : NSObject

@end
