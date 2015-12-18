//
//  GeoPackageFeatureTableCacheOverlay.h
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageTableCacheOverlay.h"
#import "GPKGFeatureOverlayQuery.h"

extern NSInteger const GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM;

@interface GeoPackageFeatureTableCacheOverlay : GeoPackageTableCacheOverlay

@property (strong, nonatomic) GPKGFeatureOverlayQuery * featureOverlayQuery;

/**
 *  Initializer
 *
 *  @param name         GeoPackage table name
 *  @param geoPackage   GeoPackage name
 *  @param cacheName    Cache name
 *  @param count        count
 *  @param minZoom      min zoom level
 *  @param indexed      indexed flag
 *  @param geometryType geometry type
 *
 *  @return new instance
 */
-(instancetype) initWithName: (NSString *) name andGeoPackage: (NSString *) geoPackage andCacheName: (NSString *) cacheName andCount: (int) count andMinZoom: (int) minZoom andIndexed: (BOOL) indexed andGeometryType: (enum WKBGeometryType) geometryType;

/**
 *  Get the indexed value
 *
 *  @return true if indexed
 */
-(BOOL) getIndexed;

/**
 *  Get the geometry type
 *
 *  @return geometry type
 */
-(enum WKBGeometryType) getGeometryType;

@end
