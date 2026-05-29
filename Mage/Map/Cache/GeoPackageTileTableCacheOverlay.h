//
//  GeoPackageTileTableCacheOverlay.h
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageTableCacheOverlay.h"
@import GeoPackage;

@interface GeoPackageTileTableCacheOverlay : GeoPackageTableCacheOverlay

/**
 *  Used to query the backing feature tables
 */
@property (strong, nonatomic) NSMutableArray<GPKGFeatureOverlayQuery *> * featureOverlayQueries;

/**
 *  Initializer
 *
 *  @param name       GeoPackage table name
 *  @param geoPackage GeoPackage name
 *  @param cacheName  Cache name
 *  @param count      count
 *  @param minZoom    min zoom level
 *  @param maxZoom    max zoom level
 *
 *  @return new instance
 */
-(instancetype) initWithName: (NSString *) name andGeoPackage: (NSString *) geoPackage andCacheName: (NSString *) cacheName andCount: (int) count andMinZoom: (int) minZoom andMaxZoom: (int) maxZoom;

@end
