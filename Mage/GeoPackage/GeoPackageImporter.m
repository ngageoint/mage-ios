//
//  GeoPackageImporter.m
//  MAGE
//
//  Created by Daniel Barela on 3/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageImporter.h"

#import "GPKGGeoPackageFactory.h"
#import "GPKGGeoPackageValidate.h"
#import "CacheOverlays.h"
#import "GeoPackageCacheOverlay.h"
#import "GeoPackageTableCacheOverlay.h"
#import "GeoPackageTileTableCacheOverlay.h"
#import "GPKGFeatureIndexManager.h"
#import "GeoPackageFeatureTableCacheOverlay.h"
#import "GPKGFeatureTileTableLinker.h"
#import "GPKGExtendedRelationsDao.h"
#import "GPKGRelationTypes.h"
#import "GPKGRelatedTablesExtension.h"
#import "GPKGMediaDao.h"
#import "MageConstants.h"
#import "XYZDirectoryCacheOverlay.h"
#import <SSZipArchive/SSZipArchive.h>

@interface GeoPackageImporter() <SSZipArchiveDelegate>
@property (nonatomic, strong) NSString *addedCacheOverlay;
@end

@implementation GeoPackageImporter

- (BOOL) handleGeoPackageImport: (NSString *) filePath {
    
    if (![GPKGGeoPackageValidate hasGeoPackageExtension:filePath]) {
        return false;
    }
        
    if ([self isGeoPackageAlreadyImported:[[filePath lastPathComponent] stringByDeletingPathExtension]]) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Overwrite Existing GeoPackage?"
                                                                       message:[NSString stringWithFormat:@"A GeoPackage with the name %@ already exists.  You can import it as a new GeoPackage, or overwrite the existing GeoPackage.", [[filePath lastPathComponent] stringByDeletingPathExtension]]
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Import As New" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // rename it and import
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
            NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [formatter setLocale:posix];
            
            [self importGeoPackageFile:filePath withName:[NSString stringWithFormat:@"%@_%@", [[filePath lastPathComponent] stringByDeletingPathExtension], [formatter stringFromDate:[NSDate date]]] andOverwrite:NO];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Overwrite Existing GeoPackage" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self importGeoPackageFile: filePath andOverwrite:YES];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Do Not Import" style:UIAlertActionStyleCancel handler:nil]];
        
        [[AppDelegate topMostController] presentViewController:alert animated:YES completion:nil];
        return false;
    } else {
        // Import the GeoPackage file
        return [self importGeoPackageFile: filePath andOverwrite:NO];
    }
    return true;
}

-(void) updateSelectedCaches: (NSString *) name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableSet * selectedCaches = [NSMutableSet setWithArray:[defaults objectForKey:MAGE_SELECTED_CACHES]];
    [selectedCaches addObject:name];
    [defaults setObject:[selectedCaches allObjects] forKey:MAGE_SELECTED_CACHES];
    [defaults synchronize];
    self.addedCacheOverlay = name;
}

-(BOOL) isGeoPackageAlreadyImported: (NSString *) name {
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    return [[manager databasesLike:name] count] != 0;
}

-(BOOL) importGeoPackageFile: (NSString *) path withName: (NSString *) name andOverwrite: (BOOL) overwrite {
    // Import the GeoPackage file
    BOOL imported = false;
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    @try {
        BOOL alreadyImported = [self isGeoPackageAlreadyImported:name];
        imported = [manager importGeoPackageFromPath:path withName:name andOverride:overwrite andMove:true];
        NSLog(@"Imported local Geopackage %d", imported);
        if (imported && !alreadyImported) {
            // index any feature tables that were not indexed already
            GPKGGeoPackage *geoPackage = [manager open:name];
            NSArray * featureTables = [geoPackage featureTables];
            for(NSString * featureTable in featureTables){
                
                GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:featureTable];
                GPKGFeatureTableIndex * featureTableIndex = [[GPKGFeatureTableIndex alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
                if(![featureTableIndex isIndexed]){
                    NSLog(@"Indexing the feature table %@", featureTable);
                    [featureTableIndex index];
                    NSLog(@"done indexing the feature table %@", featureTable);
                }
            }
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Layer *l = [Layer MR_createEntityInContext:localContext];
                l.name = name;
                l.loaded = [NSNumber numberWithFloat:Layer.EXTERNAL_LAYER_LOADED];
                l.type = @"GeoPackage";
                l.eventId = [NSNumber numberWithInt:-1];
                [self updateSelectedCaches:name];
            } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
                NSLog(@"Saved the local GeoPackage %@ with error %@", contextDidSave ? @"YES" : @"NO", error);
            }];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to import GeoPackage %@", exception);
    }
    @finally {
        [manager close];
    }
    
    if(!imported){
        NSLog(@"Error importing GeoPackage file: %@", path);
    } else {
        [self processOfflineMapArchives];
    }
    
    return imported;
}

-(BOOL) importGeoPackageFile: (NSString *) path andOverwrite: (BOOL) overwrite{
    return [self importGeoPackageFile:path withName:[[path lastPathComponent] stringByDeletingPathExtension] andOverwrite:overwrite];
}

-(BOOL) importGeoPackageFileAsLink: (NSString *) path andMove: (BOOL) moveFile withLayerId: (NSNumber *) remoteId {
    // Import the GeoPackage file
    BOOL imported = false;
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    @try {
        NSArray *alreadyImported = [manager databasesLike:[[path lastPathComponent] stringByDeletingPathExtension]];
        if ([alreadyImported count] == 1) {
            imported = YES;
        } else {
            imported = [manager importGeoPackageAsLinkToPath:path withName:[[path lastPathComponent] stringByDeletingPathExtension]];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to import GeoPackage %@", exception);
    }
    @finally {
        [manager close];
    }
    
    if(!imported){
        NSLog(@"Error importing GeoPackage file: %@", path);
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
            NSArray<Layer *> *layers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", remoteId] inContext:localContext];
            for (Layer *layer in layers) {
                layer.loaded = [NSNumber numberWithFloat: Layer.OFFLINE_LAYER_NOT_DOWNLOADED];
                layer.downloading = NO;
            }
        }];
    } else {
        NSLog(@"GeoPackage file %@ has been imported", path);
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
            NSArray<Layer *> *layers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", remoteId] inContext:localContext];
            for (Layer *layer in layers) {
                layer.loaded = [NSNumber numberWithInteger: Layer.OFFLINE_LAYER_LOADED];
                layer.downloading = NO;
            }
        } completion:^(BOOL contextDidSave, NSError * _Nullable magicalRecordError) {
            [self processOfflineMapArchives];
            [[NSNotificationCenter defaultCenter] postNotificationName:GeoPackageImported object:nil];
        }];
    }
    
    return imported;
}

-(GeoPackageCacheOverlay *) getGeoPackageCacheOverlayWithManager: (GPKGGeoPackageManager *) manager andName: (NSString *) name{
    
    GeoPackageCacheOverlay * cacheOverlay = nil;
    
    // Add the GeoPackage overlay
    GPKGGeoPackage * geoPackage = [manager open:name];
    @try {
        NSMutableArray<GeoPackageTableCacheOverlay *> * tables = [[NSMutableArray alloc] init];
        
        // GeoPackage tile tables, build a mapping between table name and the created cache overlays
        NSMutableDictionary<NSString *, GeoPackageTileTableCacheOverlay *> * tileCacheOverlays = [[NSMutableDictionary alloc] init];
        NSArray * tileTables = [geoPackage tileTables];
        for(NSString * tileTable in tileTables){
            NSString * tableCacheName = [CacheOverlay buildChildCacheNameWithName:name andChildName:tileTable];
            GPKGTileDao * tileDao = [geoPackage tileDaoWithTableName:tileTable];
            int count = [tileDao count];
            int minZoom = tileDao.minZoom;
            int maxZoom = tileDao.maxZoom;
            GeoPackageTileTableCacheOverlay * tableCache = [[GeoPackageTileTableCacheOverlay alloc] initWithName:tileTable andGeoPackage:name andCacheName:tableCacheName andCount:count andMinZoom:minZoom andMaxZoom:maxZoom];
            [tileCacheOverlays setObject:tableCache forKey:tileTable];
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // Get a linker to find tile tables linked to features
        GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
        NSMutableDictionary<NSString *, GeoPackageTileTableCacheOverlay *> * linkedTileCacheOverlays = [[NSMutableDictionary alloc] init];
        
        // GeoPackage feature tables
        NSArray * featureTables = [geoPackage featureTables];
        for(NSString * featureTable in featureTables){
            NSString * tableCacheName = [CacheOverlay buildChildCacheNameWithName:name andChildName:featureTable];
            GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:featureTable];
            int count = [featureDao count];
            enum SFGeometryType geometryType = [featureDao geometryType];
            GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
            BOOL indexed = [indexer isIndexed];
            int minZoom = 0;
            if(indexed){
                minZoom = [featureDao zoomLevel] + (int)[defaults integerForKey:@"geopackage_feature_tiles_min_zoom_offset"];
                [featureDao count];
                minZoom = MAX(minZoom, 0);
                minZoom = MIN(minZoom, (int)MAGE_FEATURES_MAX_ZOOM);
            }
            GeoPackageFeatureTableCacheOverlay * tableCache = [[GeoPackageFeatureTableCacheOverlay alloc] initWithName:featureTable andGeoPackage:name andCacheName:tableCacheName andCount:count andMinZoom:minZoom andIndexed:indexed andGeometryType:geometryType];
            
            // If indexed, check for linked tile tables
            if(indexed){
                NSArray<NSString *> * linkedTileTables = [linker tileTablesForFeatureTable:featureTable];
                for(NSString * linkedTileTable in linkedTileTables){
                    // Get the tile table cache overlay
                    GeoPackageTileTableCacheOverlay * tileCacheOverlay = [tileCacheOverlays objectForKey:linkedTileTable];
                    if(tileCacheOverlay != nil){
                        // Remove from tile cache overlays so the tile table is not added as stand alone, and add to the linked overlays
                        [tileCacheOverlays removeObjectForKey:linkedTileTable];
                        [linkedTileCacheOverlays setObject:tileCacheOverlay forKey:linkedTileTable];
                    }else{
                        // Another feature table may already be linked to this table, so check the linked overlays
                        tileCacheOverlay = [linkedTileCacheOverlays objectForKey:linkedTileTable];
                    }
                    
                    // Add the linked tile table to the feature table
                    if(tileCacheOverlay != nil){
                        [tableCache addLinkedTileTable:tileCacheOverlay];
                    }
                }
            }
            
            [tables addObject:tableCache];
        }
        
        // Add stand alone tile tables that were not linked to feature tables
        for(GeoPackageTileTableCacheOverlay * tileCacheOverlay in [tileCacheOverlays allValues]){
            [tables addObject: tileCacheOverlay];
        }
        
        // Create the GeoPackage overlay with child tables
        cacheOverlay = [[GeoPackageCacheOverlay alloc] initWithName:name andPath: geoPackage.path andTables:tables];
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to import GeoPackage %@", exception);
    }
    @finally {
        [geoPackage close];
    }
    
    return cacheOverlay;
}

- (void) removeOutdatedOfflineMapArchives {
    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext * _Nonnull localContext) {
        NSArray * layers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == -1 AND (type == %@ OR type == %@)", @"GeoPackage", @"Local_XYZ"] inContext:localContext];
        for (Layer * layer in layers) {
            CacheOverlay * overlay =  [[CacheOverlays getInstance] getByCacheName:layer.name];
            if (!overlay) {
                [layer MR_deleteEntity];
            }
            else if ([overlay isKindOfClass:[GeoPackageCacheOverlay class]]) {
                GeoPackageCacheOverlay *gpOverlay = (GeoPackageCacheOverlay *)overlay;
                if (!overlay || ![[NSFileManager defaultManager] fileExistsAtPath:gpOverlay.filePath]) {
                    [layer MR_deleteEntity];
                }
            }
        }
    }];
}


-(void) addGeoPackageCacheOverlays:(NSMutableArray<CacheOverlay *> *) cacheOverlays{
    // Add the GeoPackage caches
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    
    @try {
        //databases call only returns the geopacakge if it is named the same as the name of the actual file on disk
        NSArray * geoPackages = [manager databases];
        for(NSString * geoPackage in geoPackages){
            
            // Make sure the GeoPackage file exists
            NSString * filePath = [manager documentsPathForDatabase:geoPackage];
            if(filePath != nil && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                
                GeoPackageCacheOverlay * cacheOverlay = [self getGeoPackageCacheOverlayWithManager:manager andName:geoPackage];
                if(cacheOverlay != nil){
                    [cacheOverlays addObject:cacheOverlay];
                }
            }else{
                // this will never hit because manager.databases() call only returns files that exist
                [[CacheOverlays getInstance] removeByCacheName:[[filePath lastPathComponent] stringByDeletingPathExtension]];
                // Delete if the file was deleted
                [manager delete:geoPackage];
            }
        }
    }
    @catch (NSException *e) {
        NSLog(@"Problem getting GeoPackages %@", e);
    }
}

- (void) processOfflineMapArchives {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    NSArray *archives = [directoryContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension == %@ AND SELF != %@", @"zip", @"Form.zip"]];
    
    CacheOverlays * cacheOverlays = [CacheOverlays getInstance];
    [cacheOverlays addProcessingFromArray:archives];
    
    NSString * baseCacheDirectory = [documentsDirectory stringByAppendingPathComponent:MAGE_CACHE_DIRECTORY];
    
    // Add the existing cache directories
    NSMutableArray<CacheOverlay *> * overlays = [[NSMutableArray alloc] init];
    NSArray* caches = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:baseCacheDirectory error:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for(NSString * cache in caches){
        NSString * cacheDirectory = [baseCacheDirectory stringByAppendingPathComponent:cache];
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDirectory];
        if(isDirectory){
            CacheOverlay * cacheOverlay = [[XYZDirectoryCacheOverlay alloc] initWithName:cache andDirectory:cacheDirectory];
            [overlays addObject:cacheOverlay];
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"eventId == -1 AND (type == %@ OR type == %@) AND name == %@", @"GeoPackage", @"Local_XYZ", cache] inContext:localContext];
                if (!l) {
                    l = [Layer MR_createEntityInContext:localContext];
                    l.name = cache;
                    l.loaded = [NSNumber numberWithFloat:Layer.EXTERNAL_LAYER_LOADED];
                    l.type = @"Local_XYZ";
                    l.eventId = [NSNumber numberWithInt:-1];
                }
            }];
        }
    }
    
    // Import any GeoPackage files that were dropped in
    NSArray *geoPackageFiles = [directoryContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension == %@ OR pathExtension == %@", @"gpkg", @"gpkx"]];
    for(NSString * geoPackageFile in geoPackageFiles){
        // Import the GeoPackage file
        NSString * geoPackagePath = [documentsDirectory stringByAppendingPathComponent:geoPackageFile];
        [self importGeoPackageFile:geoPackagePath andOverwrite:NO];
    }
    
    // Add the GeoPackage cache overlays
    [self addGeoPackageCacheOverlays:overlays];
    
    // Determine which caches are enabled
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableSet * selectedCaches = [NSMutableSet setWithArray:[defaults objectForKey:MAGE_SELECTED_CACHES]];
    if([selectedCaches count] > 0){
        
        for (CacheOverlay * cacheOverlay in overlays) {
            
            // Check and enable the cache
            NSString *  cacheName = [cacheOverlay getCacheName];
            BOOL enabled = [selectedCaches containsObject:cacheName];
            
            // Check the child caches
            BOOL enableParent = false;
            for (CacheOverlay * childCache in [cacheOverlay getChildren]) {
                if (enabled || [selectedCaches containsObject:[childCache getCacheName]]) {
                    [childCache setEnabled:true];
                    enableParent = true;
                }
            }
            if(enabled || enableParent){
                [cacheOverlay setEnabled:true];
            }
            
            // Mark the cache overlay if MAGE was launched with a new cache file
            if(self.addedCacheOverlay != nil && [self.addedCacheOverlay isEqualToString:cacheName]){
                [cacheOverlay setAdded:true];
            }
        }
    }
    self.addedCacheOverlay = nil;
    
    [[CacheOverlays getInstance] addCacheOverlays:overlays];
    
    for (id archive in archives) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
            [self processArchiveAtFilePath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, archive] toDirectory:baseCacheDirectory];
        });
    }
    [self removeOutdatedOfflineMapArchives];
}

- (void) processArchiveAtFilePath:(NSString *) archivePath toDirectory:(NSString *) directory {
    NSError *error = nil;
    [SSZipArchive unzipFileAtPath:archivePath toDestination:directory delegate:self];
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:archivePath]) {
        BOOL successfulRemoval = [[NSFileManager defaultManager] removeItemAtPath:archivePath error:&error];
        if (!successfulRemoval) {
            NSLog(@"Error removing file at path: %@", error.localizedDescription);
        }
    }
}

- (void) finishDidUnzipAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath {
    CacheOverlays *cacheOverlays = [CacheOverlays getInstance];
    
    [cacheOverlays removeProcessing:[path lastPathComponent]];
    
    // There is no way to know what was in the zip that was unarchived, so just add all current caches to the list
    NSArray* caches = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:unzippedPath error:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for(NSString * cache in caches){
        NSString * cacheDirectory = [unzippedPath stringByAppendingPathComponent:cache];
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDirectory];
        if(isDirectory){
            CacheOverlay * cacheOverlay = [[XYZDirectoryCacheOverlay alloc] initWithName:cache andDirectory:cacheDirectory];
            [cacheOverlays addCacheOverlay:cacheOverlay];
            NSLog(@"Imported local XYZ Zip");
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"eventId == -1 AND (type == %@ OR type == %@) AND name == %@", @"GeoPackage", @"Local_XYZ", cache] inContext:localContext];
                if (!l) {
                    l = [Layer MR_createEntityInContext:localContext];
                    l.name = cache;
                    l.loaded = [NSNumber numberWithFloat:Layer.EXTERNAL_LAYER_LOADED];
                    l.type = @"Local_XYZ";
                    l.eventId = [NSNumber numberWithInt:-1];
                }
            }];
        }
    }
}

#pragma mark - SSZipArchiveDelegate methods
- (void) zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self finishDidUnzipAtPath:path zipInfo:zipInfo unzippedPath:unzippedPath];
    });
}
#pragma mark -

@end
