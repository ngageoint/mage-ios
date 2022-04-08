//
//  GeoPackage.m
//  MAGE
//
//  Created by Daniel Barela on 1/31/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackage.h"
#import "GPKGGeoPackageCache.h"
#import "GPKGGeoPackageFactory.h"
#import "GeoPackageCacheOverlay.h"
#import "GeoPackageTileTableCacheOverlay.h"
#import "GeoPackageFeatureTableCacheOverlay.h"
#import "GPKGOverlayFactory.h"
#import "GPKGNumberFeaturesTile.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGFeatureTileTableLinker.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGMapUtils.h"
#import "CacheOverlayUpdate.h"
#import "SFPProjection.h"
#import "SFPProjectionTransform.h"
#import "SFPProjectionConstants.h"
#import "XYZDirectoryCacheOverlay.h"

@interface GeoPackage ()
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) NSObject * cacheOverlayUpdateLock;
@property (nonatomic) BOOL updatingCacheOverlays;
@property (nonatomic) BOOL waitingCacheOverlaysUpdate;
@property (nonatomic, strong) CacheOverlayUpdate * cacheOverlayUpdate;

@property (nonatomic, strong) GPKGGeoPackageCache *geoPackageCache;
@property (nonatomic, strong) GPKGGeoPackageManager * geoPackageManager;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CacheOverlay *> *mapCacheOverlays;
@property (nonatomic, strong) GPKGBoundingBox * addedCacheBoundingBox;

@end

@implementation GeoPackage

- (id) initWithMapView: (MKMapView *) mapView {
    self = [super init];
    self.mapView = mapView;
    self.geoPackageManager = [GPKGGeoPackageFactory manager];
    self.geoPackageCache = [[GPKGGeoPackageCache alloc]initWithManager:self.geoPackageManager];
    self.cacheOverlayUpdateLock = [[NSObject alloc] init];

    if (!self.mapCacheOverlays) {
        self.mapCacheOverlays = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSArray<GeoPackageFeatureItem *>*) getFeaturesAtTap:(CLLocationCoordinate2D) tapCoord {
    NSMutableArray<GeoPackageFeatureItem *> *array = [[NSMutableArray alloc] init];
    if ([self.mapCacheOverlays count] > 0) {
        for (CacheOverlay * cacheOverlay in [self.mapCacheOverlays allValues]){
            if ([cacheOverlay isKindOfClass:[GeoPackageFeatureTableCacheOverlay class]]) {
                GeoPackageFeatureTableCacheOverlay *featureOverlay = (GeoPackageFeatureTableCacheOverlay *)cacheOverlay;
                
                NSArray <GeoPackageFeatureItem *> *items = [featureOverlay getFeaturesNearTap:tapCoord andMap:self.mapView];
                [array addObjectsFromArray:items];
            }
        }
    }
    return array;
}

/**
 *  Synchronously update the cache overlays, including overlays and features
 *
 *  @param cacheOverlays cache overlays
 */
- (void) updateCacheOverlaysSynchronized:(NSArray<CacheOverlay *> *) cacheOverlays {
    if (cacheOverlays.count == 0) {
        NSLog(@"No Cache Overlays to update");
        return;
    }
    NSLog(@"Update Cache Overlays Synchronized %@", cacheOverlays);
    @synchronized(self.cacheOverlayUpdateLock){
        
        // Set the cache overlays to update, including wiping out an update that hasn't processed
        self.cacheOverlayUpdate = [[CacheOverlayUpdate alloc] initWithCacheOverlays:cacheOverlays];
        
        // Is a thread currently updating the cache overlays?
        if(self.updatingCacheOverlays){
            // Notify the thread that there is an update waiting
            self.waitingCacheOverlaysUpdate = true;
        }else{
            
            // Start a new update thread
            self.updatingCacheOverlays = true;
            
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            dispatch_async(queue, ^{
                
                // Synchronously pull the next cache overlays to update
                CacheOverlayUpdate * overlaysToUpdate = [self getNextCacheOverlaysToUpdate];
                while(overlaysToUpdate != nil){
                    // Update the cache overlays
                    [self updateCacheOverlays:cacheOverlays];
                    overlaysToUpdate = [self getNextCacheOverlaysToUpdate];
                }
                
            });
        }
    }
    
}

/**
 *  Synchronously get the next cache overlays to update
 *
 *  @return cache overlays
 */
-(CacheOverlayUpdate *) getNextCacheOverlaysToUpdate{
    CacheOverlayUpdate * overlaysToUpdate = nil;
    // Synchronize on the update cache overlays to pull the next update
    @synchronized(self.cacheOverlayUpdateLock){
        // Get the update cache overlays and remove them
        overlaysToUpdate = self.cacheOverlayUpdate;
        self.cacheOverlayUpdate = nil;
        if(overlaysToUpdate == nil){
            // Notify that the updating thread is stopping
            self.updatingCacheOverlays = false;
        }
        // Reset the update waiting variable
        self.waitingCacheOverlaysUpdate = false;
    }
    return overlaysToUpdate;
}

/**
 *  Update all cache overlays by adding and removing overlays and features
 *
 *  @param cacheOverlays cache overlays
 */
- (void) updateCacheOverlays:(NSArray<CacheOverlay *> *) cacheOverlays {
    
    // Track enabled cache overlays
    NSMutableDictionary<NSString *, CacheOverlay *> *enabledCacheOverlays = [[NSMutableDictionary alloc] init];
    
    // Track enabled GeoPackages
    NSMutableSet<NSString *> * enabledGeoPackages = [[NSMutableSet alloc] init];
    
    // Reset the bounding box for newly added caches
//    self.addedCacheBoundingBox = nil;
    
    for (CacheOverlay *cacheOverlay in cacheOverlays) {
        
        // If this cache overlay was replaced by a new version, remove the old from the map
        if(cacheOverlay.replacedCacheOverlay != nil){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [cacheOverlay.replacedCacheOverlay removeFromMap:self.mapView];
            });
            if([cacheOverlay getType] == GEOPACKAGE){
                [self.geoPackageCache closeByName:[cacheOverlay getName]];
            }
        }
        
        // The user has asked for this overlay
        NSLog(@"The user asked for this one %@: %@", [cacheOverlay getName], cacheOverlay.enabled? @"YES" : @"NO");
        if(cacheOverlay.enabled){
            
            // Handle each type of cache overlay
            switch([cacheOverlay getType]){
                    
                case XYZ_DIRECTORY:
                    [self addXYZDirectoryCacheOverlayWithEnabled:enabledCacheOverlays andCacheOverlay:(XYZDirectoryCacheOverlay *)cacheOverlay];
                    break;
                    
                case GEOPACKAGE:
                    [self addGeoPackageCacheOverlay:enabledCacheOverlays andEnabledGeoPackages:enabledGeoPackages andCacheOverlay:(GeoPackageCacheOverlay *)cacheOverlay];
                    break;
                    
                default:
                    break;
            }
        }
        
        [cacheOverlay setAdded:false];
        [cacheOverlay setReplacedCacheOverlay:nil];
    }
    
    // Remove any overlays that are on the map but no longer selected
    for(CacheOverlay * cacheOverlay in [self.mapCacheOverlays allValues]){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [cacheOverlay removeFromMap:self.mapView];
        });
    }
    self.mapCacheOverlays = enabledCacheOverlays;
    
    // Close GeoPackages no longer enabled
    [self.geoPackageCache closeRetain:[enabledGeoPackages allObjects]];
    
    // If a new cache was added, zoom to the bounding box area
    if(self.addedCacheBoundingBox != nil){

        struct GPKGBoundingBoxSize size = [self.addedCacheBoundingBox sizeInMeters];
        CLLocationCoordinate2D center = [self.addedCacheBoundingBox center];
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center, size.height, size.width);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.mapView setRegion:region animated:true];
        });
    }
}

/**
 *  Add GeoPackage cache overlays to the map, as map overlays and/or features
 *
 *  @param enabledCacheOverlays   enabled cache overlays to add to
 *  @param enabledGeoPackages     enabled GeoPackages to add to
 *  @param geoPackageCacheOverlay cache overlay
 */
-(void) addGeoPackageCacheOverlay: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andEnabledGeoPackages: (NSMutableSet<NSString *> *) enabledGeoPackages andCacheOverlay: (GeoPackageCacheOverlay *) geoPackageCacheOverlay{
    
    // Check each GeoPackage table
    for(CacheOverlay * tableCacheOverlay in [geoPackageCacheOverlay getChildren]){
        // Check if the table is enabled
        NSLog(@"is the table enabled %@: %@", [tableCacheOverlay getName], tableCacheOverlay.enabled ? @"YES": @"NO");
        if(tableCacheOverlay.enabled){
            
            // Get and open if needed the GeoPackage
            GPKGGeoPackage * geoPackage = [self.geoPackageCache geoPackageOpenName: [geoPackageCacheOverlay getName]];
            [enabledGeoPackages addObject:geoPackage.name];
            
            // Handle tile and feature tables
            switch([tableCacheOverlay getType]){
                case GEOPACKAGE_TILE_TABLE:
                    [self addGeoPackageTileCacheOverlay:enabledCacheOverlays andCacheOverlay:(GeoPackageTileTableCacheOverlay *)tableCacheOverlay andGeoPackage:geoPackage andLinkedToFeatures:false];
                    break;
                case GEOPACKAGE_FEATURE_TABLE:
                    [self addGeoPackageFeatureCacheOverlay:enabledCacheOverlays andCacheOverlay:(GeoPackageFeatureTableCacheOverlay *)tableCacheOverlay andGeoPackage:geoPackage];
                    break;
                default:
                    [NSException raise:@"Unsupported" format:@"Unsupported GeoPackage type: %d", [tableCacheOverlay getType]];
            }
            
            // If a newly added cache, update the bounding box for zooming
            if(geoPackageCacheOverlay.added){

                GPKGContentsDao * contentsDao = [geoPackage contentsDao];
                GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:[tableCacheOverlay getName]];
                GPKGBoundingBox * contentsBoundingBox = [contents boundingBox];
                SFPProjection * projection = [contentsDao projection:contents];

                SFPProjectionTransform * transform = [[SFPProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
                GPKGBoundingBox * boundingBox = [contentsBoundingBox transform:transform];
                boundingBox = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:boundingBox];
                
                if(self.addedCacheBoundingBox == nil){
                    self.addedCacheBoundingBox = boundingBox;
                }else{
                    self.addedCacheBoundingBox = [GPKGTileBoundingBoxUtils unionWithBoundingBox:self.addedCacheBoundingBox andBoundingBox:boundingBox];
                }
                
            }
        }
    }
}

/**
 *  Add GeoPackage tile cache overlays
 *
 *  @param enabledCacheOverlays  enabled cache overlays to add to
 *  @param tileTableCacheOverlay tile table cache overlay
 *  @param geoPackage            GeoPackage
 *  @param linkedToFeatures false if a normal tile table, true if linked to a feature table
 */
-(void) addGeoPackageTileCacheOverlay: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andCacheOverlay: (GeoPackageTileTableCacheOverlay *) tileTableCacheOverlay andGeoPackage: (GPKGGeoPackage *) geoPackage andLinkedToFeatures: (BOOL) linkedToFeatures{
    
    // Retrieve the cache overlay if it already exists (and remove from cache overlays)
    NSString * cacheName = [tileTableCacheOverlay getCacheName];
    CacheOverlay * cacheOverlay = [self.mapCacheOverlays objectForKey:cacheName];
    GPKGBoundedOverlay * geoPackageTileOverlay;
    @try {
        if(cacheOverlay != nil){
            [self.mapCacheOverlays removeObjectForKey:cacheName];
            // If the existing cache overlay is being replaced, create a new cache overlay
            if(tileTableCacheOverlay.parent.replacedCacheOverlay != nil){
                cacheOverlay = nil;
            } else {
                // remove the old one and it will be re-added to preserve layer order
                [self.mapView removeOverlay:tileTableCacheOverlay.tileOverlay];
                cacheOverlay = nil;
            }
        }
        if(cacheOverlay == nil){
            // Create a new GeoPackage tile provider and add to the map
            GPKGTileDao * tileDao = [geoPackage tileDaoWithTableName:[tileTableCacheOverlay getName]];
            geoPackageTileOverlay = [GPKGOverlayFactory boundedOverlay:tileDao];
            geoPackageTileOverlay.canReplaceMapContent = false;
            [tileTableCacheOverlay setTileOverlay:geoPackageTileOverlay];
            
            // Check for linked feature tables
            [tileTableCacheOverlay.featureOverlayQueries removeAllObjects];
            GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
            NSArray<GPKGFeatureDao *> * featureDaos = [linker featureDaosForTileTable:tileDao.tableName];
            for(GPKGFeatureDao * featureDao in featureDaos){
                
                // Create the feature tiles
                GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
                
                // Create an index manager
                GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
                [featureTiles setIndexManager:indexer];
                
                // Add the feature overlay query
                GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithBoundedOverlay:geoPackageTileOverlay andFeatureTiles:featureTiles];
                [tileTableCacheOverlay.featureOverlayQueries addObject:featureOverlayQuery];
            }
        
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if (self.mapView != nil) {
                            [self.mapView addOverlay:geoPackageTileOverlay level:(linkedToFeatures ? MKOverlayLevelAboveLabels: MKOverlayLevelAboveRoads)];
                        }
                    });
        
            

            
            cacheOverlay = tileTableCacheOverlay;
        }
//         Add the cache overlay to the enabled cache overlays
        [enabledCacheOverlays setObject:cacheOverlay forKey:cacheName];
    }
    @catch (NSException *e) {
        NSLog(@"Exception adding GeoPackage tile cache overlay %@", e);
        __weak typeof(self) weakSelf = self;

        dispatch_sync(dispatch_get_main_queue(), ^{
            if (tileTableCacheOverlay != nil) {
                [tileTableCacheOverlay removeFromMap:weakSelf.mapView];
            }
            if (geoPackageTileOverlay != nil) {
                [weakSelf.mapView removeOverlay:geoPackageTileOverlay];
            }
        });
    }
}

/**
 *  Add GeoPackage feature cache overlays, as overlays when indexed or as features when not
 *
 *  @param enabledCacheOverlays     enabled cache overlays to add to
 *  @param featureTableCacheOverlay feature table cache overlay
 *  @param geoPackage               GeoPackage
 */
-(void) addGeoPackageFeatureCacheOverlay: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andCacheOverlay: (GeoPackageFeatureTableCacheOverlay *) featureTableCacheOverlay andGeoPackage: (GPKGGeoPackage *) geoPackage{
    BOOL addAsEnabled = true;
    // Retrieve the cache overlay if it already exists (and remove from cache overlays)
    NSString * cacheName = [featureTableCacheOverlay getCacheName];
    CacheOverlay * cacheOverlay = [self.mapCacheOverlays objectForKey:cacheName];
    GPKGFeatureOverlay * featureOverlay;
    @try {
        if(cacheOverlay != nil){
            [self.mapCacheOverlays removeObjectForKey:cacheName];
            // If the existing cache overlay is being replaced, create a new cache overlay
            if(featureTableCacheOverlay.parent.replacedCacheOverlay != nil){
                cacheOverlay = nil;
            }
            NSArray<GeoPackageTileTableCacheOverlay *> * linkedTileTables = [featureTableCacheOverlay getLinkedTileTables];
            if ([linkedTileTables count] != 0) {

                for(GeoPackageTileTableCacheOverlay * linkedTileTable in linkedTileTables){
                    if(cacheOverlay != nil){
                        // Add the existing linked tile cache overlays
                        [self addGeoPackageTileCacheOverlay:enabledCacheOverlays andCacheOverlay:linkedTileTable andGeoPackage:geoPackage andLinkedToFeatures:true];
                    }
                    [self.mapCacheOverlays removeObjectForKey:[linkedTileTable getCacheName]];
                }
            } else if ([featureTableCacheOverlay tileOverlay] != nil) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.mapView addOverlay:[featureTableCacheOverlay tileOverlay] level:MKOverlayLevelAboveLabels];
                });
            }
        }
        if(cacheOverlay == nil){
//             Add the features to the map
            GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:[featureTableCacheOverlay getName]];

            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

            // If indexed, add as a tile overlay
            if([featureTableCacheOverlay getIndexed]){
                GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
                NSInteger maxFeaturesPerTile = 0;
                if([featureDao geometryType] == SF_POINT){
                    maxFeaturesPerTile = [defaults geoPackageFeatureTilesMaxPointsPerTile];
                }else{
                    maxFeaturesPerTile = [defaults geoPackageFeatureTilesMaxFeaturesPerTile];
                }
                [featureTiles setMaxFeaturesPerTile:[NSNumber numberWithInteger: maxFeaturesPerTile]];
                GPKGNumberFeaturesTile * numberFeaturesTile = [[GPKGNumberFeaturesTile alloc] init];
                // Adjust the max features number tile draw paint attributes here as needed to
                // change how tiles are drawn when more than the max features exist in a tile
                [featureTiles setMaxFeaturesTileDraw:numberFeaturesTile];
                [featureTiles setIndexManager:[[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao]];
                // Adjust the feature tiles draw paint attributes here as needed to change how
                // features are drawn on tiles
                featureOverlay = [[GPKGFeatureOverlay alloc] initWithFeatureTiles:featureTiles];
                [featureOverlay setMinZoom:[NSNumber numberWithInt:[featureTableCacheOverlay getMinZoom]]];

                GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
                NSArray<GPKGTileDao *> * tileDaos = [linker tileDaosForFeatureTable:featureDao.tableName];
                [featureOverlay ignoreTileDaos:tileDaos];

                GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithFeatureOverlay:featureOverlay];
                [featureTableCacheOverlay setFeatureOverlayQuery:featureOverlayQuery];
                featureOverlay.canReplaceMapContent = false;
                [featureTableCacheOverlay setTileOverlay:featureOverlay];
                [featureOverlay setMinZoom:[NSNumber numberWithInt:0]];
                [featureOverlay setMaxZoom:[NSNumber numberWithInt:21]];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.mapView addOverlay:featureOverlay level:MKOverlayLevelAboveLabels];
                });
                cacheOverlay = featureTableCacheOverlay;
            }
            // Not indexed, add the features to the map
            else {
                NSInteger maxFeaturesPerTable = 0;
                if([featureDao geometryType] == SF_POINT){
                    maxFeaturesPerTable = [defaults geoPackageFeaturesMaxPointsPerTable];
                }else{
                    maxFeaturesPerTable = [defaults geoPackageFeaturesMaxFeaturesPerTable];
                }
                SFPProjection * projection = featureDao.projection;
                GPKGMapShapeConverter * shapeConverter = [[GPKGMapShapeConverter alloc] initWithProjection:projection];
                GPKGResultSet * resultSet = [featureDao queryForAll];
                @try {
                    int totalCount = [resultSet count];
                    int count = 0;
                    while([resultSet moveToNext]){
                        // If there is another cache overlay update waiting, stop and remove this overlay to let the next update handle it
                        if(self.waitingCacheOverlaysUpdate){
                            addAsEnabled = false;
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [featureTableCacheOverlay removeFromMap:self.mapView];
                            });
                            break;
                        }
                        GPKGFeatureRow * featureRow = [featureDao featureRow:resultSet];
                        GPKGGeometryData * geometryData = [featureRow geometry];
                        if(geometryData != nil && !geometryData.empty){
                            SFGeometry * geometry = geometryData.geometry;
                            if(geometry != nil){
                                @try {
                                    GPKGMapShape * shape = [shapeConverter toShapeWithGeometry:geometry];
                                    [featureTableCacheOverlay addShapeWithId:[featureRow id] andShape:shape];
                                    dispatch_sync(dispatch_get_main_queue(), ^{
                                        [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
                                    });
                                }
                                @catch (NSException *e) {
                                    NSLog(@"Failed to parse geometry: %@", e);
                                }

                                if(++count >= maxFeaturesPerTable){
                                    if(count < totalCount){
                                        NSLog(@"%@- added %d of %d", cacheName, count, totalCount);
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
                @finally {
                    [resultSet close];
                }
            }

            // Add linked tile tables
            for(GeoPackageTileTableCacheOverlay * linkedTileTable in [featureTableCacheOverlay getLinkedTileTables]){
                [self addGeoPackageTileCacheOverlay:enabledCacheOverlays andCacheOverlay:linkedTileTable andGeoPackage:geoPackage andLinkedToFeatures:true];
            }

            cacheOverlay = featureTableCacheOverlay;
        }
        
        // If not cancelled for a waiting update
        if(addAsEnabled){
            // Add the cache overlay to the enabled cache overlays
            [enabledCacheOverlays setObject:cacheOverlay forKey:cacheName];
        }
    }
    @catch (NSException *e) {
        NSLog(@"Exception adding GeoPackage feature cache overlay %@", e);
        __weak typeof(self) weakSelf = self;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (featureTableCacheOverlay != nil) {
                [featureTableCacheOverlay removeFromMap:weakSelf.mapView];
            }
            if (featureOverlay != nil) {
                [self.mapView removeOverlay:featureOverlay];
            }
        });
    }
}

-(void) addXYZDirectoryCacheOverlayWithEnabled: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andCacheOverlay: (XYZDirectoryCacheOverlay *) xyzDirectoryCacheOverlay{
    // Retrieve the cache overlay if it already exists (and remove from cache overlays)
    NSString * cacheName = [xyzDirectoryCacheOverlay getCacheName];
    CacheOverlay * cacheOverlay = [self.mapCacheOverlays objectForKey:cacheName];
    if(cacheOverlay == nil){
        
        // Set the cache directory path
        NSString *cacheDirectory = [xyzDirectoryCacheOverlay getDirectory];
        
        // Find the image extension type
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:cacheDirectory];
        NSString * patternExtension = nil;
        for (NSString *file in enumerator) {
            NSString * extension = [file pathExtension];
            if([extension caseInsensitiveCompare:@"png"] == NSOrderedSame ||
               [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame ||
               [extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame){
                patternExtension = extension;
                break;
            }
        }
        
        NSString *template = [NSString stringWithFormat:@"file://%@/{z}/{x}/{y}", cacheDirectory];
        if(patternExtension != nil){
            template = [NSString stringWithFormat:@"%@.%@", template, patternExtension];
        }
        MKTileOverlay *tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
        tileOverlay.minimumZ = xyzDirectoryCacheOverlay.minZoom;
        tileOverlay.maximumZ = xyzDirectoryCacheOverlay.maxZoom;
        [xyzDirectoryCacheOverlay setTileOverlay:tileOverlay];
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"Adding xyz cache");
            [self.mapView addOverlay:tileOverlay level:MKOverlayLevelAboveRoads];
        });
        
        cacheOverlay = xyzDirectoryCacheOverlay;
    }else{
        [self.mapCacheOverlays removeObjectForKey:cacheName];
    }
    // Add the cache overlay to the enabled cache overlays
    [enabledCacheOverlays setObject:cacheOverlay forKey:cacheName];
    
}

@end
