//
//  GeoPackageCacheOverlay.h
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "CacheOverlay.h"
#import "GeoPackageTableCacheOverlay.h"

/**
 *  GeoPackage file cache overlay
 */
@interface GeoPackageCacheOverlay : CacheOverlay

@property (nonatomic, strong) NSString *filePath;

/**
 *  Initializer
 *
 *  @param name   name
 *  @param tables GeoPackage cache tables
 *
 *  @return new instance
 */
-(instancetype) initWithName: (NSString *) name andPath: (NSString *) filePath andTables: (NSArray<GeoPackageTableCacheOverlay *> *) tables;

@end
