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
import GeoPackage
import SimpleFeatures
import SimpleFeaturesProjections

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
        MageLogger.misc.debug("Update Cache Overlays: \(cacheOverlays)")
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
            MageLogger.misc.debug("The user asked for this one \(cacheOverlay.name): \(cacheOverlay.enabled ? "YES" : "NO")")
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
            MageLogger.misc.debug("is the table enabled \(tableCacheOverlay.name): \(tableCacheOverlay.enabled ? "YES": "NO")");
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
                            }
                        }
                        cacheOverlay = tileTableCacheOverlay
                    }
                }
                // Add the cache overlay to the enabled cache overlays
                enabledCacheOverlays[cacheName] = cacheOverlay
            }
        } catch {
            MageLogger.misc.error("Exception adding GeoPackage tile cache overlay \(error)")
            tileTableCacheOverlay.removeFromMap(mapView: mapView)
            if let geoPackageTileOverlay {
                geoPackageTileOverlay.close()
                Task {
                    await removeOverlay(mapView: mapView, overlay: geoPackageTileOverlay)
                }
            }
        }
    }
    
    @MainActor
    func addOverlay(mapView: MKMapView, overlay: MKOverlay, level: MKOverlayLevel) {
        MageLogger.misc.debug("XXX geopackage map view \(mapView)")
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
        MageLogger.misc.debug("XXX cache overlay \(cacheOverlay)")
        MageLogger.misc.debug("XXX cache overlays \(self.mapCacheOverlays)")
        MageLogger.misc.debug("XXX cache overlay name \(cacheName)")
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
                            if featureDao.geometryType() == .POINT {
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
                            if featureDao.geometryType() == .POINT {
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
                                                    MageLogger.misc.error("Failed to parse geometry: \(error)")
                                                }
                                                
                                                count += 1
                                                if count >= maxFeaturesPerTable {
                                                    if count < totalCount {
                                                        MageLogger.misc.debug("\(cacheName) - added \(count) of \(totalCount)")
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
            MageLogger.misc.error("Exception adding GeoPackage feature cache overlay \(error)")
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
