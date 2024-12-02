//
//  GeoPackage.m
//  MAGE
//
//  Created by Daniel Barela on 1/31/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

/**
 - (id) initWithMapView: (MKMapView *) mapView;
 - (void) updateCacheOverlaysSynchronized:(NSArray<CacheOverlay *> *) cacheOverlays;
 - (NSArray<GeoPackageFeatureKey *>*) getFeatureKeysAtTap: (CLLocationCoordinate2D) tapCoord;
 */

import Foundation
import ExceptionCatcher
import geopackage_ios
import sf_ios
import sf_proj_ios

@objc actor GeoPackage: NSObject {
    
    var mapView: MKMapView
    var cacheOverlayUpdate: [CacheOverlay]?
    
    lazy var geoPackageCache: GPKGGeoPackageCache = {
        GPKGGeoPackageCache(manager: geoPackageManager)
    }()
    var geoPackageManager: GPKGGeoPackageManager = GPKGGeoPackageManager()
    var mapCacheOverlays: [String: CacheOverlay] = [:]
    var addedCacheBoundingBox: GPKGBoundingBox?
    
    @objc public init(mapView: MKMapView) {
        self.mapView = mapView
    }
    
    @objc public func getFeatureKeys(atTap: CLLocationCoordinate2D) async -> [GeoPackageFeatureKey] {
        var keys: [GeoPackageFeatureKey] = []
        for case let cacheOverlay as GeoPackageFeatureTableCacheOverlay in mapCacheOverlays.values {
            await keys.append(contentsOf: cacheOverlay.getFeatureKeysNear(location: atTap, mapView: mapView))
        }
        return keys
    }
    
    @objc public func updateCacheOverlaysSynchronized(_ cacheOverlays: [CacheOverlay]) async {
        NSLog("Update Cache Overlays %@", cacheOverlays)
        cacheOverlayUpdate = cacheOverlays
        var overlaysToUpdate = getNextCacheOverlaysToUpdate()
        while(overlaysToUpdate != nil) {
            updateCacheOverlays(cacheOverlays: overlaysToUpdate!)
            overlaysToUpdate = getNextCacheOverlaysToUpdate()
        }
    }
    
    func getNextCacheOverlaysToUpdate() -> [CacheOverlay]? {
        let overlaysToUpdate = self.cacheOverlayUpdate
        self.cacheOverlayUpdate = nil
        return overlaysToUpdate
    }
    
    func updateCacheOverlays(cacheOverlays: [CacheOverlay]) {
        // Track enabled cache overlays
        var enabledCacheOverlays: [String: CacheOverlay] = [:]
        
        // Track enabled GeoPackages
        var enabledGeoPackages: Set<String> = Set()
        
        // Reset the bounding box for enwly added caches
        addedCacheBoundingBox = nil
        
        for cacheOverlay in cacheOverlays {
            // If this cache overlay was replaced by a new version, remove the old from the map
            if let replaced = cacheOverlay.replaced {
                replaced.removeFromMap(mapView: mapView)
                if cacheOverlay.type == .GEOPACKAGE {
                    geoPackageCache.close(byName: cacheOverlay.name)
                }
            }
            
            // the user has asked for this overlay
            NSLog("The user asked for this one \(cacheOverlay.name): \(cacheOverlay.enabled ? "YES" : "NO")")
            if cacheOverlay.enabled {
                switch cacheOverlay.type {
                case .GEOPACKAGE:
                    if let cacheOverlay = cacheOverlay as? GeoPackageCacheOverlay {
                        addGeoPackageCacheOverlay(enabledCacheOverlays: &enabledCacheOverlays, enabledGeoPackages: &enabledGeoPackages, geoPackageCacheOverlay: cacheOverlay)
                    }
                case .XYZ_DIRECTORY:
                    if let cacheOverlay = cacheOverlay as? XYZDirectoryCacheOverlay {
                        addXYZDirectoryCacheOverlay(enabledCacheOverlays: &enabledCacheOverlays, xyzDirectoryCacheOverlay: cacheOverlay)
                    }
                default:
                    break
                }
            }
            cacheOverlay.added = false
            cacheOverlay.replaced = nil
        }
        
        // Remove any overlays that are on the map but no longer selected
        for cacheOverlay in mapCacheOverlays.values {
            cacheOverlay.removeFromMap(mapView: mapView)
        }
        self.mapCacheOverlays = enabledCacheOverlays
        
        // Close GeoPackages no longer enabled
        geoPackageCache.closeRetain(Array(enabledGeoPackages))
        
        // If a new cache was added, zoom to the bounding box area
        if let addedCacheBoundingBox = addedCacheBoundingBox {
            let size = addedCacheBoundingBox.sizeInMeters()
            let center = addedCacheBoundingBox.center()
            let region = MKCoordinateRegion(center: center, latitudinalMeters: size.height, longitudinalMeters: size.width)
            Task {
                await setRegion(mapView: mapView, region: region)
            }
        }
    }
    
    @MainActor
    func setRegion(mapView: MKMapView, region: MKCoordinateRegion) {
        mapView.setRegion(region, animated: true)
    }
    
    func addGeoPackageCacheOverlay(enabledCacheOverlays: inout [String: CacheOverlay], enabledGeoPackages: inout Set<String>, geoPackageCacheOverlay: GeoPackageCacheOverlay) {
        
        // Check each GeoPackage table
        for tableCacheOverlay in geoPackageCacheOverlay.getChildren() {
            // Check if the table is enabled
            NSLog("is the table enabled \(tableCacheOverlay.name): \(tableCacheOverlay.enabled ? "YES": "NO")");
            if(tableCacheOverlay.enabled){
                // Get and open if needed the GeoPackage
                guard let geoPackage = geoPackageCache.geoPackageOpenName(geoPackageCacheOverlay.name) else { continue }
                enabledGeoPackages.insert(geoPackage.name)

                // Handle tile and feature tables
                switch tableCacheOverlay.type {
                case .GEOPACKAGE_TILE_TABLE:
                    if let tableCacheOverlay = tableCacheOverlay as? GeoPackageTileTableCacheOverlay {
                        addGeoPackageTileCacheOverlay(
                            enabledCacheOverlays: &enabledCacheOverlays,
                            tileTableCacheOverlay: tableCacheOverlay,
                            geoPackage: geoPackage,
                            linkedToFeatures: false
                        )
                    }
                case .GEOPACKAGE_FEATURE_TABLE:
                    if let tableCacheOverlay = tableCacheOverlay as? GeoPackageFeatureTableCacheOverlay {
                        addGeoPackageFeatureCacheOverlay(
                            enabledCacheOverlays: &enabledCacheOverlays,
                            featureTableCacheOverlay: tableCacheOverlay,
                            geoPackage: geoPackage
                        )
                    }
                default:
                    continue
                }
                // If a newly added cache, update the bounding box for zooming
                if(geoPackageCacheOverlay.added){
                    if let contentsDao = geoPackage.contentsDao(),
                       let contents = contentsDao.query(forIdObject: tableCacheOverlay.name as NSObject) as? GPKGContents,
                       let contentsBoundingBox = contents.boundingBox(),
                       let projection = contentsDao.projection(contents),
                       let transform = SFPGeometryTransform(from: projection, andToEpsg: PROJ_EPSG_WORLD_GEODETIC_SYSTEM)
                    {
                        var boundingBox = contentsBoundingBox.transform(transform)
                        transform.destroy()
                        boundingBox = GPKGTileBoundingBoxUtils.boundWgs84BoundingBox(withWebMercatorLimits: boundingBox)
                        if let addedCacheBoundingBox {
                            self.addedCacheBoundingBox = GPKGTileBoundingBoxUtils.union(with: addedCacheBoundingBox, andBoundingBox: boundingBox)
                        } else {
                            self.addedCacheBoundingBox = boundingBox
                        }
                    }
                }
            }
        }
    }
    
    func addGeoPackageTileCacheOverlay(enabledCacheOverlays: inout [String: CacheOverlay], tileTableCacheOverlay: GeoPackageTileTableCacheOverlay, geoPackage: GPKGGeoPackage, linkedToFeatures: Bool) {
        // Retrieve the cache overlay if it already exists (and remove from cache overlays)
        let cacheName = tileTableCacheOverlay.cacheName
        var cacheOverlay = enabledCacheOverlays[cacheName]
        var geoPackageTileOverlay: GPKGBoundedOverlay?
        do {
            try ExceptionCatcher.catch {
                if cacheOverlay != nil {
                    mapCacheOverlays.removeValue(forKey: cacheName)
                    // If the existing cache overlay is being replaced, create a new cache overlay
                    if tileTableCacheOverlay.parent?.replaced?.cacheName != nil {
                        cacheOverlay = nil
                    } else {
                        // remove the old one and it will be re-added to preserve layer order
                        if let tileOverlay = tileTableCacheOverlay.tileOverlay as? GPKGBoundedOverlay {
                            tileOverlay.close()
                        }
                        if let tileOverlay = tileTableCacheOverlay.tileOverlay {
                            Task {
                                await removeOverlay(mapView: mapView, overlay: tileOverlay)
                            }
//                            mapView.removeOverlay(tileOverlay)
                        }
                        cacheOverlay = nil
                    }
                }
                
                if cacheOverlay == nil {
                    // Create a new GeoPackage tile provider and add to the map
                    if let tileDao = geoPackage.tileDao(withTableName: tileTableCacheOverlay.name),
                       let gpTileOverlay = GPKGOverlayFactory.boundedOverlay(tileDao)
                    {
                        geoPackageTileOverlay = gpTileOverlay
                        gpTileOverlay.canReplaceMapContent = false
                        tileTableCacheOverlay.tileOverlay = gpTileOverlay
                        
                        // Check for linked feature tables
                        for query in tileTableCacheOverlay.featureOverlayQueries {
                            query.close()
                        }
                        
                        tileTableCacheOverlay.featureOverlayQueries.removeAll()
                        if let linker = GPKGFeatureTileTableLinker(geoPackage: geoPackage),
                           let featureDaos = linker.featureDaos(forTileTable: tileDao.tableName)
                        {
                            for featureDao in featureDaos {
                                // Create the feature tiles
                                if let featureTiles = GPKGFeatureTiles(featureDao: featureDao) {
                                    
                                    // Create an index manager
                                    let indexer = GPKGFeatureIndexManager(geoPackage: geoPackage, andFeatureDao: featureDao)
                                    featureTiles.indexManager = indexer
                                    
                                    // Add the feature overlay query
                                    if let featureOverlayQuery = GPKGFeatureOverlayQuery(
                                        boundedOverlay: geoPackageTileOverlay,
                                        andFeatureTiles: featureTiles
                                    ) {
                                        tileTableCacheOverlay.featureOverlayQueries.append(featureOverlayQuery)
                                    }
                                }
                            }
                            if let geoPackageTileOverlay {
                                Task {
                                    await addOverlay(mapView: mapView, overlay: geoPackageTileOverlay, level: linkedToFeatures ? .aboveLabels : .aboveRoads)
                                }
                                
//                                mapView.addOverlay(geoPackageTileOverlay, level: linkedToFeatures ? .aboveLabels : .aboveRoads)
                            }
                        }
                        cacheOverlay = tileTableCacheOverlay
                    }
                }
                // Add the cache overlay to the enabled cache overlays
                enabledCacheOverlays[cacheName] = cacheOverlay
            }
        } catch {
            NSLog("Exception adding GeoPackage tile cache overlay \(error)")
            tileTableCacheOverlay.removeFromMap(mapView: mapView)
            if let geoPackageTileOverlay {
                geoPackageTileOverlay.close()
                Task {
                    await removeOverlay(mapView: mapView, overlay: geoPackageTileOverlay)
                }
//                mapView.removeOverlay(geoPackageTileOverlay)
            }
        }
    }
    
    @MainActor
    func addOverlay(mapView: MKMapView, overlay: MKOverlay, level: MKOverlayLevel) {
        print("XXX geopackage map view \(mapView)")
        mapView.addOverlay(overlay, level: level)
    }
    
    @MainActor
    func removeOverlay(mapView: MKMapView, overlay: MKOverlay) {
        mapView.removeOverlay(overlay)
    }
    
    func addGeoPackageFeatureCacheOverlay(
        enabledCacheOverlays: inout [String: CacheOverlay],
        featureTableCacheOverlay: GeoPackageFeatureTableCacheOverlay,
        geoPackage: GPKGGeoPackage
    ) {
        var addAsEnabled: Bool = true
        
        // Retrieve the cache overlay if it already exists (and remove from cache overlays)
        let cacheName = featureTableCacheOverlay.cacheName
        var cacheOverlay = self.mapCacheOverlays[cacheName]
        print("XXX cache overlay \(cacheOverlay)")
        print("XXX cache overlays \(self.mapCacheOverlays)")
        print("XXX cache overlay name \(cacheName)")
        var featureOverlay: GPKGFeatureOverlay?
        do {
            try ExceptionCatcher.catch {
                if cacheOverlay != nil {
                    mapCacheOverlays.removeValue(forKey: cacheName)
                    // If the existing cache overlay is being replaced, create a new cache overlay
                    if featureTableCacheOverlay.parent?.replaced != nil {
                        cacheOverlay = nil
                    }
                    let linkedTileTables = featureTableCacheOverlay.linkedTiles
                    if !linkedTileTables.isEmpty {
                        for linkedTileTable in linkedTileTables {
                            if cacheOverlay != nil {
                                // Add the existing linked tile cache overlays
                                addGeoPackageTileCacheOverlay(
                                    enabledCacheOverlays: &enabledCacheOverlays,
                                    tileTableCacheOverlay: linkedTileTable,
                                    geoPackage: geoPackage,
                                    linkedToFeatures: true
                                )
                            }
                            mapCacheOverlays.removeValue(forKey: linkedTileTable.cacheName)
                        }
                    } else if let tileOverlay = featureTableCacheOverlay.tileOverlay {
                        Task {
                            await addOverlay(mapView: mapView, overlay: tileOverlay, level: .aboveLabels)
                        }
                    }
                }
                
                if cacheOverlay == nil {
                    // Add the features to the map
                    if let featureDao = geoPackage.featureDao(withTableName: featureTableCacheOverlay.name) {
                        // If indexed, add as a tile overlay
                        if featureTableCacheOverlay.indexed {
                            let featureTiles = GPKGFeatureTiles(geoPackage: geoPackage, andFeatureDao: featureDao)
                            var maxFeaturesPerTile = UserDefaults.standard.geoPackageFeatureTilesMaxFeaturesPerTile
                            if featureDao.geometryType() == SF_POINT {
                                maxFeaturesPerTile = UserDefaults.standard.geoPackageFeatureTilesMaxPointsPerTile
                            }
                            featureTiles?.maxFeaturesPerTile = NSNumber(value: maxFeaturesPerTile)
                            let numberFeaturesTile = GPKGNumberFeaturesTile()
                            // Adjust the max features number tile draw paint attributes here as needed to
                            // change how tiles are drawn when more than the max features exist in a tile
                            featureTiles?.maxFeaturesTileDraw = numberFeaturesTile
                            featureTiles?.indexManager = GPKGFeatureIndexManager(geoPackage: geoPackage, andFeatureDao: featureDao)
                            // Adjust the feature tiles draw paint attributes here as needed to change how
                            // features are drawn on tiles
                            featureOverlay = GPKGFeatureOverlay(featureTiles: featureTiles)
                            featureOverlay?.minZoom = NSNumber(value: featureTableCacheOverlay.minZoom)
                            let linker = GPKGFeatureTileTableLinker(geoPackage: geoPackage)
                            let tileDaos = linker?.tileDaos(forFeatureTable: featureDao.tableName)
                            featureOverlay?.ignore(tileDaos)
                            if let featureOverlay {
                                let featureOverlayQuery = GPKGFeatureOverlayQuery(featureOverlay: featureOverlay)
                                featureTableCacheOverlay.featureOverlayQuery = featureOverlayQuery
                                featureOverlay.canReplaceMapContent = false
                                featureTableCacheOverlay.tileOverlay = featureOverlay
                                featureOverlay.minZoom = 0
                                featureOverlay.maxZoom = 21
                                Task {
                                    await addOverlay(mapView: mapView, overlay: featureOverlay, level: .aboveLabels)
                                }
                            }
                            cacheOverlay = featureTableCacheOverlay
                        } else {
                            // Not indexed, add the features to the map
                            var maxFeaturesPerTable = UserDefaults.standard.geoPackageFeaturesMaxFeaturesPerTable
                            if featureDao.geometryType() == SF_POINT {
                                maxFeaturesPerTable = UserDefaults.standard.geoPackageFeaturesMaxPointsPerTable
                            }
                            if let projection = featureDao.projection,
                               let shapeConverter = GPKGMapShapeConverter(projection: projection),
                               let resultSet = featureDao.queryForAll()
                            {
                                do {
                                    try ExceptionCatcher.catch {
                                        let totalCount = resultSet.count
                                        var count = 0
                                        while (resultSet.moveToNext()) {
                                            if let featureRow = featureDao.featureRow(resultSet),
                                               let geometryData = featureRow.geometry(),
                                               !geometryData.empty,
                                               let geometry = geometryData.geometry
                                            {
                                                do {
                                                    try ExceptionCatcher.catch {
                                                        if let shape = shapeConverter.toShape(with: geometry) {
                                                            featureTableCacheOverlay.addShape(id: featureRow.id(), shape: shape)
                                                            Task { @MainActor in
                                                                await GPKGMapShapeConverter.add(shape, to: mapView)
                                                            }
                                                        }
                                                    }
                                                } catch {
                                                    NSLog("Failed to parse geometry: \(error)")
                                                }
                                                
                                                count += 1
                                                if count >= maxFeaturesPerTable {
                                                    if count < totalCount {
                                                        NSLog("\(cacheName) - added \(count) of \(totalCount)")
                                                    }
                                                    break
                                                }
                                            }
                                            
                                        }
                                        
                                        resultSet.close()
                                        shapeConverter.close()
                                    }
                                } catch {
                                    resultSet.close()
                                    shapeConverter.close()
                                }
                            }
                        }
                        
                        // Add linked tile tables
                        for linkedTileTable in featureTableCacheOverlay.getLinkedTileTables() {
                            addGeoPackageTileCacheOverlay(
                                enabledCacheOverlays: &enabledCacheOverlays,
                                tileTableCacheOverlay: linkedTileTable,
                                geoPackage: geoPackage,
                                linkedToFeatures: true
                            )
                        }
                        
                        cacheOverlay = featureTableCacheOverlay
                    }
                }
                
                if addAsEnabled {
                    enabledCacheOverlays[cacheName] = cacheOverlay
                }
            }
        } catch {
            NSLog("Exception adding GeoPackage feature cache overlay \(error)")
            featureTableCacheOverlay.removeFromMap(mapView: mapView)
            if let featureOverlay {
                featureOverlay.close()
                Task {
                    await removeOverlay(mapView: mapView, overlay: featureOverlay)
                }
            }
        }
    }
    
    func addXYZDirectoryCacheOverlay(
        enabledCacheOverlays: inout [String: CacheOverlay],
        xyzDirectoryCacheOverlay: XYZDirectoryCacheOverlay
    ) {
        // Retrieve the cache overlay if it already exists (and remove from cache overlays)
        let cacheName = xyzDirectoryCacheOverlay.cacheName
        var cacheOverlay = self.mapCacheOverlays[cacheName]
        if cacheOverlay == nil {
            if let cacheDirectory = xyzDirectoryCacheOverlay.directory,
               let enumerator = FileManager.default.enumerator(atPath: cacheDirectory)
            {
                // Find the image extension type
                var patternExtension: String?
                while let file = enumerator.nextObject() as? NSString {
                    let ext = file.pathExtension
                    if ext.caseInsensitiveCompare("png") == .orderedSame
                        || ext.caseInsensitiveCompare("jpeg") == .orderedSame
                        || ext.caseInsensitiveCompare("jpg") == .orderedSame {
                        patternExtension = ext
                        break
                    }
                }
                
                var template = "file://\(cacheDirectory)/{z}/{x}/{y}"
                if let patternExtension {
                    template = "\(template).\(patternExtension)"
                }
                let tileOverlay = MKTileOverlay(urlTemplate: template)
                tileOverlay.minimumZ = xyzDirectoryCacheOverlay.minZoom
                tileOverlay.maximumZ = xyzDirectoryCacheOverlay.maxZoom
                xyzDirectoryCacheOverlay.tileOverlay = tileOverlay
                Task {
                    await addOverlay(mapView: mapView, overlay: tileOverlay, level: .aboveRoads)
                }
                cacheOverlay = xyzDirectoryCacheOverlay
            }
        } else {
            self.mapCacheOverlays.removeValue(forKey: cacheName)
        }
        enabledCacheOverlays[cacheName] = cacheOverlay
    }
}


//
//#import "GeoPackage.h"
//#import "GPKGGeoPackageCache.h"
//#import "GPKGGeoPackageFactory.h"
//#import "GeoPackageCacheOverlay.h"
//#import "GeoPackageTileTableCacheOverlay.h"
//#import "GeoPackageFeatureTableCacheOverlay.h"
//#import "GPKGOverlayFactory.h"
//#import "GPKGNumberFeaturesTile.h"
//#import "GPKGMapShapeConverter.h"
//#import "GPKGFeatureTileTableLinker.h"
//#import "GPKGTileBoundingBoxUtils.h"
//#import "GPKGMapUtils.h"
//#import "CacheOverlayUpdate.h"
//#import "PROJProjectionConstants.h"
//#import "XYZDirectoryCacheOverlay.h"
//#import "MAGE-Swift.h"
//
//@interface GeoPackage ()
//@property (nonatomic, strong) MKMapView *mapView;
//@property (nonatomic, strong) NSObject * cacheOverlayUpdateLock;
//@property (nonatomic) BOOL updatingCacheOverlays;
//@property (nonatomic) BOOL waitingCacheOverlaysUpdate;
//@property (nonatomic, strong) CacheOverlayUpdate * cacheOverlayUpdate;
//
//@property (nonatomic, strong) GPKGGeoPackageCache *geoPackageCache;
//@property (nonatomic, strong) GPKGGeoPackageManager * geoPackageManager;
//@property (nonatomic, strong) NSMutableDictionary<NSString *, CacheOverlay *> *mapCacheOverlays;
//@property (nonatomic, strong) GPKGBoundingBox * addedCacheBoundingBox;
//
//@end
//
//@implementation GeoPackage
//
//- (id) initWithMapView: (MKMapView *) mapView {
//    self = [super init];
//    self.mapView = mapView;
//    self.geoPackageManager = [GPKGGeoPackageFactory manager];
//    self.geoPackageCache = [[GPKGGeoPackageCache alloc]initWithManager:self.geoPackageManager];
//    self.cacheOverlayUpdateLock = [[NSObject alloc] init];
//
//    if (!self.mapCacheOverlays) {
//        self.mapCacheOverlays = [[NSMutableDictionary alloc] init];
//    }
//    return self;
//}
//
//- (nonnull NSArray<GeoPackageFeatureKey *> *) getFeatureKeysAtTap:(CLLocationCoordinate2D) tapCoord {
//    NSMutableArray<GeoPackageFeatureKey *> *array = [[NSMutableArray alloc] init];
//    if ([self.mapCacheOverlays count] > 0) {
//        for (CacheOverlay * cacheOverlay in [self.mapCacheOverlays allValues]){
//            if ([cacheOverlay isKindOfClass:[GeoPackageFeatureTableCacheOverlay class]]) {
//                GeoPackageFeatureTableCacheOverlay *featureOverlay = (GeoPackageFeatureTableCacheOverlay *)cacheOverlay;
//                
//                NSArray <GeoPackageFeatureKey *> *items = [featureOverlay getFeatureKeysNearTap:tapCoord andMap:self.mapView];
//                [array addObjectsFromArray:items];
//            }
//        }
//    }
//    return array;
//}
//
///**
// *  Synchronously update the cache overlays, including overlays and features
// *
// *  @param cacheOverlays cache overlays
// */
//- (void) updateCacheOverlaysSynchronized:(NSArray<CacheOverlay *> *) cacheOverlays {
//    if (cacheOverlays.count == 0) {
//        NSLog(@"No Cache Overlays to update");
//        return;
//    }
//    NSLog(@"Update Cache Overlays Synchronized %@", cacheOverlays);
//    @synchronized(self.cacheOverlayUpdateLock){
//        
//        // Set the cache overlays to update, including wiping out an update that hasn't processed
//        self.cacheOverlayUpdate = [[CacheOverlayUpdate alloc] initWithCacheOverlays:cacheOverlays];
//        
//        // Is a thread currently updating the cache overlays?
//        if(self.updatingCacheOverlays){
//            // Notify the thread that there is an update waiting
//            self.waitingCacheOverlaysUpdate = true;
//        }else{
//            
//            // Start a new update thread
//            self.updatingCacheOverlays = true;
//            
//            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
//            dispatch_async(queue, ^{
//                
//                // Synchronously pull the next cache overlays to update
//                CacheOverlayUpdate * overlaysToUpdate = [self getNextCacheOverlaysToUpdate];
//                while(overlaysToUpdate != nil){
//                    // Update the cache overlays
//                    [self updateCacheOverlays:cacheOverlays];
//                    overlaysToUpdate = [self getNextCacheOverlaysToUpdate];
//                }
//                
//            });
//        }
//    }
//    
//}
//
///**
// *  Synchronously get the next cache overlays to update
// *
// *  @return cache overlays
// */
//-(CacheOverlayUpdate *) getNextCacheOverlaysToUpdate{
//    CacheOverlayUpdate * overlaysToUpdate = nil;
//    // Synchronize on the update cache overlays to pull the next update
//    @synchronized(self.cacheOverlayUpdateLock){
//        // Get the update cache overlays and remove them
//        overlaysToUpdate = self.cacheOverlayUpdate;
//        self.cacheOverlayUpdate = nil;
//        if(overlaysToUpdate == nil){
//            // Notify that the updating thread is stopping
//            self.updatingCacheOverlays = false;
//        }
//        // Reset the update waiting variable
//        self.waitingCacheOverlaysUpdate = false;
//    }
//    return overlaysToUpdate;
//}
//
///**
// *  Update all cache overlays by adding and removing overlays and features
// *
// *  @param cacheOverlays cache overlays
// */
//- (void) updateCacheOverlays:(NSArray<CacheOverlay *> *) cacheOverlays {
//    
//    // Track enabled cache overlays
//    NSMutableDictionary<NSString *, CacheOverlay *> *enabledCacheOverlays = [[NSMutableDictionary alloc] init];
//    
//    // Track enabled GeoPackages
//    NSMutableSet<NSString *> * enabledGeoPackages = [[NSMutableSet alloc] init];
//    
//    // Reset the bounding box for newly added caches
////    self.addedCacheBoundingBox = nil;
//    
//    for (CacheOverlay *cacheOverlay in cacheOverlays) {
//        
//        // If this cache overlay was replaced by a new version, remove the old from the map
//        if(cacheOverlay.replacedCacheOverlay != nil){
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                [cacheOverlay.replacedCacheOverlay removeFromMap:self.mapView];
//            });
//            if([cacheOverlay getType] == GEOPACKAGE){
//                [self.geoPackageCache closeByName:[cacheOverlay getName]];
//            }
//        }
//        
//        // The user has asked for this overlay
//        NSLog(@"The user asked for this one %@: %@", [cacheOverlay getName], cacheOverlay.enabled? @"YES" : @"NO");
//        if(cacheOverlay.enabled){
//            
//            // Handle each type of cache overlay
//            switch([cacheOverlay getType]){
//                    
//                case XYZ_DIRECTORY:
//                    [self addXYZDirectoryCacheOverlayWithEnabled:enabledCacheOverlays andCacheOverlay:(XYZDirectoryCacheOverlay *)cacheOverlay];
//                    break;
//                    
//                case GEOPACKAGE:
//                    [self addGeoPackageCacheOverlay:enabledCacheOverlays andEnabledGeoPackages:enabledGeoPackages andCacheOverlay:(GeoPackageCacheOverlay *)cacheOverlay];
//                    break;
//                    
//                default:
//                    break;
//            }
//        }
//        
//        [cacheOverlay setAdded:false];
//        [cacheOverlay setReplacedCacheOverlay:nil];
//    }
//    
//    // Remove any overlays that are on the map but no longer selected
//    for(CacheOverlay * cacheOverlay in [self.mapCacheOverlays allValues]){
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [cacheOverlay removeFromMap:self.mapView];
//        });
//    }
//    self.mapCacheOverlays = enabledCacheOverlays;
//    
//    // Close GeoPackages no longer enabled
//    [self.geoPackageCache closeRetain:[enabledGeoPackages allObjects]];
//    
//    // If a new cache was added, zoom to the bounding box area
//    if(self.addedCacheBoundingBox != nil){
//
//        struct GPKGBoundingBoxSize size = [self.addedCacheBoundingBox sizeInMeters];
//        CLLocationCoordinate2D center = [self.addedCacheBoundingBox center];
//        NSLog(@"Center is %f, %f", center.longitude, center.latitude);
//        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center, size.height, size.width);
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [self.mapView setRegion:region animated:true];
//        });
//    }
//}
//
///**
// *  Add GeoPackage cache overlays to the map, as map overlays and/or features
// *
// *  @param enabledCacheOverlays   enabled cache overlays to add to
// *  @param enabledGeoPackages     enabled GeoPackages to add to
// *  @param geoPackageCacheOverlay cache overlay
// */
//-(void) addGeoPackageCacheOverlay: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andEnabledGeoPackages: (NSMutableSet<NSString *> *) enabledGeoPackages andCacheOverlay: (GeoPackageCacheOverlay *) geoPackageCacheOverlay{
//    
//    // Check each GeoPackage table
//    for(CacheOverlay * tableCacheOverlay in [geoPackageCacheOverlay getChildren]){
//        // Check if the table is enabled
//        NSLog(@"is the table enabled %@: %@", [tableCacheOverlay getName], tableCacheOverlay.enabled ? @"YES": @"NO");
//        if(tableCacheOverlay.enabled){
//            
//            // Get and open if needed the GeoPackage
//            GPKGGeoPackage * geoPackage = [self.geoPackageCache geoPackageOpenName: [geoPackageCacheOverlay getName]];
//            [enabledGeoPackages addObject:geoPackage.name];
//            
//            // Handle tile and feature tables
//            switch([tableCacheOverlay getType]){
//                case GEOPACKAGE_TILE_TABLE:
//                    [self addGeoPackageTileCacheOverlay:enabledCacheOverlays andCacheOverlay:(GeoPackageTileTableCacheOverlay *)tableCacheOverlay andGeoPackage:geoPackage andLinkedToFeatures:false];
//                    break;
//                case GEOPACKAGE_FEATURE_TABLE:
//                    [self addGeoPackageFeatureCacheOverlay:enabledCacheOverlays andCacheOverlay:(GeoPackageFeatureTableCacheOverlay *)tableCacheOverlay andGeoPackage:geoPackage];
//                    break;
//                default:
//                    [NSException raise:@"Unsupported" format:@"Unsupported GeoPackage type: %d", [tableCacheOverlay getType]];
//            }
//            
//            // If a newly added cache, update the bounding box for zooming
//            if(geoPackageCacheOverlay.added){
//
//                GPKGContentsDao * contentsDao = [geoPackage contentsDao];
//                GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:[tableCacheOverlay getName]];
//                GPKGBoundingBox * contentsBoundingBox = [contents boundingBox];
//                PROJProjection * projection = [contentsDao projection:contents];
//
//                SFPGeometryTransform *transform = [[SFPGeometryTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
//                GPKGBoundingBox * boundingBox = [contentsBoundingBox transform:transform];
//                [transform destroy];
//                boundingBox = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:boundingBox];
//                
//                if(self.addedCacheBoundingBox == nil){
//                    self.addedCacheBoundingBox = boundingBox;
//                }else{
//                    self.addedCacheBoundingBox = [GPKGTileBoundingBoxUtils unionWithBoundingBox:self.addedCacheBoundingBox andBoundingBox:boundingBox];
//                }
//                
//            }
//        }
//    }
//}
//
///**
// *  Add GeoPackage tile cache overlays
// *
// *  @param enabledCacheOverlays  enabled cache overlays to add to
// *  @param tileTableCacheOverlay tile table cache overlay
// *  @param geoPackage            GeoPackage
// *  @param linkedToFeatures false if a normal tile table, true if linked to a feature table
// */
//-(void) addGeoPackageTileCacheOverlay: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andCacheOverlay: (GeoPackageTileTableCacheOverlay *) tileTableCacheOverlay andGeoPackage: (GPKGGeoPackage *) geoPackage andLinkedToFeatures: (BOOL) linkedToFeatures{
//    
//    // Retrieve the cache overlay if it already exists (and remove from cache overlays)
//    NSString * cacheName = [tileTableCacheOverlay getCacheName];
//    CacheOverlay * cacheOverlay = [self.mapCacheOverlays objectForKey:cacheName];
//    GPKGBoundedOverlay * geoPackageTileOverlay;
//    @try {
//        if(cacheOverlay != nil){
//            [self.mapCacheOverlays removeObjectForKey:cacheName];
//            // If the existing cache overlay is being replaced, create a new cache overlay
//            if(tileTableCacheOverlay.parent.replacedCacheOverlay != nil){
//                cacheOverlay = nil;
//            } else {
//                // remove the old one and it will be re-added to preserve layer order
//                if ([tileTableCacheOverlay.tileOverlay isKindOfClass:[GPKGBoundedOverlay class]]){
//                    [((GPKGBoundedOverlay *)tileTableCacheOverlay.tileOverlay) close];
//                }
//                [self.mapView removeOverlay:tileTableCacheOverlay.tileOverlay];
//                cacheOverlay = nil;
//            }
//        }
//        if(cacheOverlay == nil){
//            // Create a new GeoPackage tile provider and add to the map
//            GPKGTileDao * tileDao = [geoPackage tileDaoWithTableName:[tileTableCacheOverlay getName]];
//            geoPackageTileOverlay = [GPKGOverlayFactory boundedOverlay:tileDao];
//            geoPackageTileOverlay.canReplaceMapContent = false;
//            [tileTableCacheOverlay setTileOverlay:geoPackageTileOverlay];
//            
//            // Check for linked feature tables
//            for (GPKGFeatureOverlayQuery *query in tileTableCacheOverlay.featureOverlayQueries) {
//                [query close];
//            }
//            [tileTableCacheOverlay.featureOverlayQueries removeAllObjects];
//            GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
//            NSArray<GPKGFeatureDao *> * featureDaos = [linker featureDaosForTileTable:tileDao.tableName];
//            for(GPKGFeatureDao * featureDao in featureDaos){
//                
//                // Create the feature tiles
//                GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
//                
//                // Create an index manager
//                GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
//                [featureTiles setIndexManager:indexer];
//                
//                // Add the feature overlay query
//                GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithBoundedOverlay:geoPackageTileOverlay andFeatureTiles:featureTiles];
//                [tileTableCacheOverlay.featureOverlayQueries addObject:featureOverlayQuery];
//            }
//        
//                    dispatch_sync(dispatch_get_main_queue(), ^{
//                        if (self.mapView != nil) {
//                            [self.mapView addOverlay:geoPackageTileOverlay level:(linkedToFeatures ? MKOverlayLevelAboveLabels: MKOverlayLevelAboveRoads)];
//                        }
//                    });
//        
//            
//
//            
//            cacheOverlay = tileTableCacheOverlay;
//        }
////         Add the cache overlay to the enabled cache overlays
//        [enabledCacheOverlays setObject:cacheOverlay forKey:cacheName];
//    }
//    @catch (NSException *e) {
//        NSLog(@"Exception adding GeoPackage tile cache overlay %@", e);
//        __weak typeof(self) weakSelf = self;
//
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            if (tileTableCacheOverlay != nil) {
//                [tileTableCacheOverlay removeFromMap:weakSelf.mapView];
//            }
//            if (geoPackageTileOverlay != nil) {
//                [geoPackageTileOverlay close];
//                [weakSelf.mapView removeOverlay:geoPackageTileOverlay];
//            }
//        });
//    }
//}
//
///**
// *  Add GeoPackage feature cache overlays, as overlays when indexed or as features when not
// *
// *  @param enabledCacheOverlays     enabled cache overlays to add to
// *  @param featureTableCacheOverlay feature table cache overlay
// *  @param geoPackage               GeoPackage
// */
//-(void) addGeoPackageFeatureCacheOverlay: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andCacheOverlay: (GeoPackageFeatureTableCacheOverlay *) featureTableCacheOverlay andGeoPackage: (GPKGGeoPackage *) geoPackage{
//    BOOL addAsEnabled = true;
//    // Retrieve the cache overlay if it already exists (and remove from cache overlays)
//    NSString * cacheName = [featureTableCacheOverlay getCacheName];
//    CacheOverlay * cacheOverlay = [self.mapCacheOverlays objectForKey:cacheName];
//    GPKGFeatureOverlay * featureOverlay;
//    @try {
//        if(cacheOverlay != nil){
//            [self.mapCacheOverlays removeObjectForKey:cacheName];
//            // If the existing cache overlay is being replaced, create a new cache overlay
//            if(featureTableCacheOverlay.parent.replacedCacheOverlay != nil){
//                cacheOverlay = nil;
//            }
//            NSArray<GeoPackageTileTableCacheOverlay *> * linkedTileTables = [featureTableCacheOverlay getLinkedTileTables];
//            if ([linkedTileTables count] != 0) {
//
//                for(GeoPackageTileTableCacheOverlay * linkedTileTable in linkedTileTables){
//                    if(cacheOverlay != nil){
//                        // Add the existing linked tile cache overlays
//                        [self addGeoPackageTileCacheOverlay:enabledCacheOverlays andCacheOverlay:linkedTileTable andGeoPackage:geoPackage andLinkedToFeatures:true];
//                    }
//                    [self.mapCacheOverlays removeObjectForKey:[linkedTileTable getCacheName]];
//                }
//            } else if ([featureTableCacheOverlay tileOverlay] != nil) {
//                dispatch_sync(dispatch_get_main_queue(), ^{
//                    [self.mapView addOverlay:[featureTableCacheOverlay tileOverlay] level:MKOverlayLevelAboveLabels];
//                });
//            }
//        }
//        if(cacheOverlay == nil){
////             Add the features to the map
//            GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:[featureTableCacheOverlay getName]];
//
//            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//
//            // If indexed, add as a tile overlay
//            if([featureTableCacheOverlay getIndexed]){
//                GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
//                NSInteger maxFeaturesPerTile = 0;
//                if([featureDao geometryType] == SF_POINT){
//                    maxFeaturesPerTile = [defaults geoPackageFeatureTilesMaxPointsPerTile];
//                }else{
//                    maxFeaturesPerTile = [defaults geoPackageFeatureTilesMaxFeaturesPerTile];
//                }
//                [featureTiles setMaxFeaturesPerTile:[NSNumber numberWithInteger: maxFeaturesPerTile]];
//                GPKGNumberFeaturesTile * numberFeaturesTile = [[GPKGNumberFeaturesTile alloc] init];
//                // Adjust the max features number tile draw paint attributes here as needed to
//                // change how tiles are drawn when more than the max features exist in a tile
//                [featureTiles setMaxFeaturesTileDraw:numberFeaturesTile];
//                [featureTiles setIndexManager:[[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao]];
//                // Adjust the feature tiles draw paint attributes here as needed to change how
//                // features are drawn on tiles
//                featureOverlay = [[GPKGFeatureOverlay alloc] initWithFeatureTiles:featureTiles];
//                [featureOverlay setMinZoom:[NSNumber numberWithInt:[featureTableCacheOverlay getMinZoom]]];
//
//                GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
//                NSArray<GPKGTileDao *> * tileDaos = [linker tileDaosForFeatureTable:featureDao.tableName];
//                [featureOverlay ignoreTileDaos:tileDaos];
//
//                GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithFeatureOverlay:featureOverlay];
//                [featureTableCacheOverlay setFeatureOverlayQuery:featureOverlayQuery];
//                featureOverlay.canReplaceMapContent = false;
//                [featureTableCacheOverlay setTileOverlay:featureOverlay];
//                [featureOverlay setMinZoom:[NSNumber numberWithInt:0]];
//                [featureOverlay setMaxZoom:[NSNumber numberWithInt:21]];
//                
//                dispatch_sync(dispatch_get_main_queue(), ^{
//                    [self.mapView addOverlay:featureOverlay level:MKOverlayLevelAboveLabels];
//                });
//                cacheOverlay = featureTableCacheOverlay;
//            }
//            // Not indexed, add the features to the map
//            else {
//                NSInteger maxFeaturesPerTable = 0;
//                if([featureDao geometryType] == SF_POINT){
//                    maxFeaturesPerTable = [defaults geoPackageFeaturesMaxPointsPerTable];
//                }else{
//                    maxFeaturesPerTable = [defaults geoPackageFeaturesMaxFeaturesPerTable];
//                }
//                PROJProjection * projection = featureDao.projection;
//                GPKGMapShapeConverter * shapeConverter = [[GPKGMapShapeConverter alloc] initWithProjection:projection];
//                GPKGResultSet * resultSet = [featureDao queryForAll];
//                @try {
//                    int totalCount = [resultSet count];
//                    int count = 0;
//                    while([resultSet moveToNext]){
//                        // If there is another cache overlay update waiting, stop and remove this overlay to let the next update handle it
//                        if(self.waitingCacheOverlaysUpdate){
//                            addAsEnabled = false;
//                            dispatch_sync(dispatch_get_main_queue(), ^{
//                                [featureTableCacheOverlay removeFromMap:self.mapView];
//                            });
//                            break;
//                        }
//                        GPKGFeatureRow * featureRow = [featureDao featureRow:resultSet];
//                        GPKGGeometryData * geometryData = [featureRow geometry];
//                        if(geometryData != nil && !geometryData.empty){
//                            SFGeometry * geometry = geometryData.geometry;
//                            if(geometry != nil){
//                                @try {
//                                    GPKGMapShape * shape = [shapeConverter toShapeWithGeometry:geometry];
//                                    [featureTableCacheOverlay addShapeWithId:[featureRow id] andShape:shape];
//                                    dispatch_sync(dispatch_get_main_queue(), ^{
//                                        [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
//                                    });
//                                }
//                                @catch (NSException *e) {
//                                    NSLog(@"Failed to parse geometry: %@", e);
//                                }
//
//                                if(++count >= maxFeaturesPerTable){
//                                    if(count < totalCount){
//                                        NSLog(@"%@- added %d of %d", cacheName, count, totalCount);
//                                    }
//                                    break;
//                                }
//                            }
//                        }
//                    }
//                }
//                @finally {
//                    [resultSet close];
//                    [shapeConverter close];
//                }
//            }
//
//            // Add linked tile tables
//            for(GeoPackageTileTableCacheOverlay * linkedTileTable in [featureTableCacheOverlay getLinkedTileTables]){
//                [self addGeoPackageTileCacheOverlay:enabledCacheOverlays andCacheOverlay:linkedTileTable andGeoPackage:geoPackage andLinkedToFeatures:true];
//            }
//
//            cacheOverlay = featureTableCacheOverlay;
//        }
//        
//        // If not cancelled for a waiting update
//        if(addAsEnabled){
//            // Add the cache overlay to the enabled cache overlays
//            [enabledCacheOverlays setObject:cacheOverlay forKey:cacheName];
//        }
//    }
//    @catch (NSException *e) {
//        NSLog(@"Exception adding GeoPackage feature cache overlay %@", e);
//        __weak typeof(self) weakSelf = self;
//        
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            if (featureTableCacheOverlay != nil) {
//                [featureTableCacheOverlay removeFromMap:weakSelf.mapView];
//            }
//            if (featureOverlay != nil) {
//                [featureOverlay close];
//                [self.mapView removeOverlay:featureOverlay];
//            }
//        });
//    }
//}
//
//-(void) addXYZDirectoryCacheOverlayWithEnabled: (NSMutableDictionary<NSString *, CacheOverlay *> *) enabledCacheOverlays andCacheOverlay: (XYZDirectoryCacheOverlay *) xyzDirectoryCacheOverlay{
//    // Retrieve the cache overlay if it already exists (and remove from cache overlays)
//    NSString * cacheName = [xyzDirectoryCacheOverlay getCacheName];
//    CacheOverlay * cacheOverlay = [self.mapCacheOverlays objectForKey:cacheName];
//    if(cacheOverlay == nil){
//        
//        // Set the cache directory path
//        NSString *cacheDirectory = [xyzDirectoryCacheOverlay getDirectory];
//        
//        // Find the image extension type
//        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:cacheDirectory];
//        NSString * patternExtension = nil;
//        for (NSString *file in enumerator) {
//            NSString * extension = [file pathExtension];
//            if([extension caseInsensitiveCompare:@"png"] == NSOrderedSame ||
//               [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame ||
//               [extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame){
//                patternExtension = extension;
//                break;
//            }
//        }
//        
//        NSString *template = [NSString stringWithFormat:@"file://%@/{z}/{x}/{y}", cacheDirectory];
//        if(patternExtension != nil){
//            template = [NSString stringWithFormat:@"%@.%@", template, patternExtension];
//        }
//        MKTileOverlay *tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
//        tileOverlay.minimumZ = xyzDirectoryCacheOverlay.minZoom;
//        tileOverlay.maximumZ = xyzDirectoryCacheOverlay.maxZoom;
//        [xyzDirectoryCacheOverlay setTileOverlay:tileOverlay];
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            NSLog(@"Adding xyz cache");
//            [self.mapView addOverlay:tileOverlay level:MKOverlayLevelAboveRoads];
//        });
//        
//        cacheOverlay = xyzDirectoryCacheOverlay;
//    }else{
//        [self.mapCacheOverlays removeObjectForKey:cacheName];
//    }
//    // Add the cache overlay to the enabled cache overlays
//    [enabledCacheOverlays setObject:cacheOverlay forKey:cacheName];
//    
//}
//
//@end
