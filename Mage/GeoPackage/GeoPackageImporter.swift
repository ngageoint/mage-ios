//
//  GeoPackageImporter.m
//  MAGE
//
//  Created by Daniel Barela on 3/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import geopackage_ios
import ExceptionCatcher
import SSZipArchive

@objc class GeoPackageImporter: NSObject {
    @Injected(\.layerRepository)
    var layerRepository: LayerRepository
    
    var addedCacheOverlay: String?
    
    @objc public func handleGeoPackageImport(_ filePath: String) async -> Bool {

        if (!GPKGGeoPackageValidate.hasGeoPackageExtension(filePath)) {
            return false;
        }
        
        let fileNSString: NSString = filePath as NSString
        let fileWithoutExtension = (fileNSString.lastPathComponent as NSString).deletingPathExtension

        if isGeoPackageAlreadyImported(name: fileWithoutExtension) {
            
            let alert = await UIAlertController(
                title: "Overwrite Existing GeoPackage?",
                message: "A GeoPackage with the name \((((filePath as NSString).lastPathComponent) as NSString).deletingPathExtension) already exists.  You can import it as a new GeoPackage, or overwrite the existing GeoPackage.",
                preferredStyle: .actionSheet
            )
            
            await alert.addAction(UIAlertAction(title: "Import As New", style: .default, handler: { action in
                Task {
                    // rename it and import
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    
                    _ = await self.importGeoPackageFile(filePath, name: "\(fileWithoutExtension)_\(formatter.string(from: Date()))", overwrite: false)
                }
            }))
            
            await alert.addAction(UIAlertAction(title: "Overwrite Existing GeoPackage", style: .destructive, handler: { action in
                Task {
                    await self.importGeoPackageFile(filePath, overwrite: true)
                }
            }))

            await alert.addAction(UIAlertAction(title: "Do Not Import", style: .cancel, handler: nil));

            await AppDelegate.topMostController().present(alert, animated: true)
            return false;
        } else {
            // Import the GeoPackage file
            return await importGeoPackageFile(filePath, overwrite: false)
        }
    }
    
    @objc public func processOfflineMapArchives() async {
        guard let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
        let directoryContent = try? FileManager.default.contentsOfDirectory(atPath: documentsDirectory)
        
        let archives = directoryContent?.filter({ fileName in
            let fileExtension = (fileName as NSString).pathExtension
            return fileExtension == "zip" && !fileName.hasSuffix("Form.zip")
        })
        
        let cacheOverlays = CacheOverlays.getInstance()
        await cacheOverlays.addProcessing(from: archives)
        
        let baseCacheDirectory = (documentsDirectory  as NSString).appendingPathComponent(MageDirectories.cache.rawValue)
        
        // Add the existing cache directories
        var overlays: [CacheOverlay] = []
        let caches = try? FileManager.default.contentsOfDirectory(atPath: baseCacheDirectory)
        for cache in caches ?? [] {
            let cacheDirectory = (baseCacheDirectory as NSString).appendingPathComponent(cache)
            var isDirectory: ObjCBool = false
            var exists = FileManager.default.fileExists(atPath: cacheDirectory, isDirectory: &isDirectory)
            if exists && isDirectory.boolValue {
                let cacheOverlay = XYZDirectoryCacheOverlay(name: cache, directory: cacheDirectory)
                overlays.append(cacheOverlay)
                
                _ = await layerRepository.createLoadedXYZLayer(name: cache)
            }
        }
        
        // Import any GeoPackage files that were dropped in
        let geoPackageFiles = directoryContent?.filter({ fileName in
            let fileExtension = (fileName as NSString).pathExtension
            return fileExtension == "gpkg" || fileExtension == "gpkx"
        }) ?? []

        for geoPackageFile in geoPackageFiles {
            // Import the GeoPackage file
            let geoPackagePath = (documentsDirectory as NSString).appendingPathComponent(geoPackageFile)
            _ = await self.importGeoPackageFile(geoPackagePath, overwrite: false)
        }
        
        // Add the GeoPackage cache overlays
        let geoPackageCacheOverlays = addGeoPackageCacheOverlays()
        overlays.append(contentsOf: geoPackageCacheOverlays)

        // Determine which caches are enabled
        var selectedCaches = UserDefaults.standard.selectedCaches ?? []
        if selectedCaches.count > 0 {
            for cacheOverlay in overlays {
                // Check and enable the cache
                let cacheName = cacheOverlay.cacheName
                let enabled = selectedCaches.contains { name in
                    name == cacheName
                }
                
                // Check the child caches
                var enableParent = false
                for childCache in cacheOverlay.getChildren() {
                    if enabled || selectedCaches.contains(where: { name in
                        name == childCache.cacheName
                    }) {
                        childCache.enabled = true
                        enableParent = true
                    }
                }
                if enabled || enableParent {
                    cacheOverlay.enabled = true
                }
                
                // Mark the cache overlay if MAGE was launched with a new cache file
                if (addedCacheOverlay != nil && addedCacheOverlay == cacheName) {
                    cacheOverlay.added = true
                }
            }
        }
        addedCacheOverlay = nil
        
        await cacheOverlays.add(overlays)
        
        for archive in archives ?? [] {
            let queue = DispatchQueue.global(qos: .background)
            queue.async { [weak self] in
                self?.processArchiveAtFilePath(archivePath: (documentsDirectory as NSString).appendingPathComponent(archive), directory: baseCacheDirectory)
            }
        }
        
        await self.removeOutdatedOfflineMapArchives()
    }
    
    @objc public func importGeoPackageFileAsLink(_ path: String, andMove: Bool, withLayerId: NSNumber) async -> Bool {
        let name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        var imported = false
        let manager = GPKGGeoPackageFactory.manager()
        
        do {
            imported = try ExceptionCatcher.catch {
                var imported = false
                if self.isGeoPackageAlreadyImported(name: name) {
                    imported = true
                } else {
                    imported = manager?.importGeoPackageAsLink(toPath: path, withName: name) ?? false
                }
                return imported
            }
        } catch {
            imported = false
            MageLogger.misc.error("Failed to import GeoPackage \(error)")
        }
        manager?.close()
        
        if !imported {
            MageLogger.misc.error("Error importing GeoPackage file: \(path)")
            
            await layerRepository.markRemoteLayerNotDownloaded(remoteId: withLayerId)
        } else {
            MageLogger.misc.debug("GeoPackage file %@ has been imported", path)
            await layerRepository.markRemoteLayerLoaded(remoteId: withLayerId)
            await self.processOfflineMapArchives()
            MageLogger.misc.debug("XXX sending gp imported")
            NotificationCenter.default.post(name: .GeoPackageImported, object: nil)
        }
        return imported
    }
    
    private func isGeoPackageAlreadyImported(name: String) -> Bool {
        let manager = GPKGGeoPackageFactory.manager()
        return manager?.databasesLike(name).count != 0
    }
    
    private func importGeoPackageFile(_ path: String, name: String? = nil, overwrite: Bool) async -> Bool {
        let name = name ?? ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        
        // Import the GeoPackage file
        var imported = false
        let manager = GPKGGeoPackageFactory.manager()
        do {
            imported = try ExceptionCatcher.catch {
                var imported = false
                let alreadyImported = self.isGeoPackageAlreadyImported(name: name)
                imported = manager?.importGeoPackage(fromPath: path, withName: name, andOverride: overwrite, andMove: true) ?? false
                MageLogger.misc.debug("Imported local Geopackage \(imported)")
                if (imported && !alreadyImported) {
                    if let geoPackage = manager?.open(name) {
                        // index any feature tables that were not indexed already
                        for featureTable in geoPackage.featureTables() ?? [] {
                            let featureDao = geoPackage.featureDao(withTableName: featureTable)
                            if let featureTableIndex = GPKGFeatureTableIndex(geoPackage: geoPackage, andFeatureDao: featureDao) {
                                if !featureTableIndex.isIndexed() {
                                    let count = featureTableIndex.index()
                                    MageLogger.misc.debug("Indexed \(featureTable) with \(count) features")
                                }
                            }
                        }
                        Task {
                            _ = await layerRepository.createGeoPackageLayer(name: name)
                            self.updateSelectedCaches(name: name)
                        }
                    }
                }
                return imported
            }
        } catch {
            imported = false
            MageLogger.misc.error("Failed to import GeoPackage \(error)")
        }
        manager?.close()
        
        if !imported {
            MageLogger.misc.error("Error importing GeoPackage file: \(path)")
        } else {
            await processOfflineMapArchives()
        }
        return imported
    }
    
    func updateSelectedCaches(name: String) {
        var selectedCaches = UserDefaults.standard.selectedCaches ?? []
        selectedCaches.append(name)
        UserDefaults.standard.selectedCaches = selectedCaches
        self.addedCacheOverlay = name
    }
    
    func addGeoPackageCacheOverlays() -> [GeoPackageCacheOverlay] {
        // Add the GeoPackage caches
        guard let manager = GPKGGeoPackageFactory.manager() else { return [] }
        
        var cacheOverlays: [GeoPackageCacheOverlay] = []
        do {
            try ExceptionCatcher.catch {
                //databases call only returns the geopacakge if it is named the same as the name of the actual file on disk
                let geoPackages = manager.databases() as? [String] ?? []
                for geoPackage in geoPackages {
                    // Make sure the GeoPackage file exists
                    let filePath = manager.documentsPath(forDatabase: geoPackage)
                    if let filePath = filePath, FileManager.default.fileExists(atPath: filePath) {
                        if let cacheOverlay = getGeoPackageCacheOverlay(manager: manager, name: geoPackage) {
                            cacheOverlays.append(cacheOverlay)
                        }
                    } else {
                        // this will never hit because manager.databases() call only returns files that exist
                    }
                }
            }
        } catch {
            MageLogger.misc.error("Problem getting GeoPackages \(error)")
        }
        return cacheOverlays
    }

    func processArchiveAtFilePath(archivePath: String, directory: String) {
        SSZipArchive.unzipFile(atPath: archivePath, toDestination: directory, delegate: self)
    }
    func getGeoPackageCacheOverlay(manager: GPKGGeoPackageManager, name: String) -> GeoPackageCacheOverlay? {
        var cacheOverlay: GeoPackageCacheOverlay?
        
        // Add the GeoPackage overlay
        guard let geoPackage = manager.open(name) else {
            return nil
        }
        do {
            try ExceptionCatcher.catch {
                var tables: [GeoPackageTableCacheOverlay] = []
                
                // GeoPackage tile tables, build a mapping between table name and the created cache overlays
                var tileCacheOverlays: [String: GeoPackageTileTableCacheOverlay] = [:]
                for tileTable in geoPackage.tileTables() ?? [] {
                    let tableCacheName = CacheOverlay.buildChildCacheName(name: name, childName: tileTable)
                    if let tileDao = geoPackage.tileDao(withTableName: tileTable) {
                        let count = tileDao.count()
                        let minZoom = tileDao.minZoom
                        let maxZoom = tileDao.maxZoom
                        let tableCache = GeoPackageTileTableCacheOverlay(
                            name: tileTable,
                            geoPackage: name,
                            cacheName: tableCacheName,
                            count: Int(count),
                            minZoom: Int(minZoom),
                            maxZoom: Int(maxZoom)
                        )
                        tileCacheOverlays[tileTable] = tableCache
                    }
                }
                
                // Get a linker to find tile tables linked to features
                let linker = GPKGFeatureTileTableLinker(geoPackage: geoPackage)
                var linkedTileCacheOverlays: [String: GeoPackageTileTableCacheOverlay] = [:]
                
                // GeoPackage feature tables
                let featureTables = geoPackage.featureTables() ?? []
                for featureTable in featureTables {
                    let tableCacheName = CacheOverlay.buildChildCacheName(name: name, childName: featureTable)
                    if let featureDao = geoPackage.featureDao(withTableName: featureTable) {
                        let count = featureDao.count()
                        let geometryType = featureDao.geometryType()
                        let indexer = GPKGFeatureIndexManager(geoPackage: geoPackage, andFeatureDao: featureDao)
                        let indexed = indexer?.isIndexed() ?? false
                        var minZoom: Int32 = 0
                        if indexed {
                            minZoom = featureDao.zoomLevel() + Int32(UserDefaults.standard.integer(forKey: "geopackage_feature_tiles_min_zoom_offset"))
                            minZoom = max(minZoom, 0)
                            minZoom = min(minZoom, Int32(MageZooms.featureMaxZoom.rawValue))
                        }
                        
                        let tableCache = GeoPackageFeatureTableCacheOverlay(
                            name: featureTable,
                            geoPackage: name,
                            cacheName: tableCacheName,
                            count: Int(count),
                            minZoom: Int(minZoom),
                            indexed: indexed,
                            geometryType: geometryType
                        )
                        
                        // If index, check for linked tile tables
                        if indexed {
                            let linkedTileTables = linker?.tileTables(forFeatureTable: featureTable) ?? []
                            for linkedTileTable in linkedTileTables {
                                // Get the tile table cahce overlay
                                var tileCacheOverlay = tileCacheOverlays[linkedTileTable]
                                if let tileCacheOverlay = tileCacheOverlay {
                                    // Remove from tile cache overlays so the tile table is not added as stand alone, and add to the linked overlays
                                    tileCacheOverlays.removeValue(forKey: linkedTileTable)
                                    linkedTileCacheOverlays[linkedTileTable] = tileCacheOverlay
                                } else {
                                    // Another feature table may already be linked to this table, so check the linked overlays
                                    tileCacheOverlay = linkedTileCacheOverlays[linkedTileTable]
                                }
                                
                                // Add the linked tile table to the feature table
                                if let tileCacheOverlay = tileCacheOverlay {
                                    tableCache.addLinkedTileTable(tileTable: tileCacheOverlay)
                                }
                            }
                        }
                        
                        tables.append(tableCache)
                    }
                }
                    
                // Add stand alone tile talbes that were not linked to feature tables
                for tileCacheOverlay in tileCacheOverlays.values {
                    tables.append(tileCacheOverlay)
                }
                
                // Create the GeoPackage overlay with child tables
                cacheOverlay = GeoPackageCacheOverlay(name: name, path: geoPackage.path, tables: tables)
                
            }
        } catch {
            MageLogger.misc.error("Failed to import GeoPackage \(error)")
        }
        geoPackage.close()
        
        return cacheOverlay
    }

    func removeOutdatedOfflineMapArchives() async {
        await layerRepository.removeOutdatedOfflineMapArchives()
    }
}

extension GeoPackageImporter: SSZipArchiveDelegate {
    
    func zipArchiveDidUnzipArchive(atPath path: String, zipInfo: unz_global_info, unzippedPath: String) {
        Task { [weak self] in
            await self?.finishDidUnzipAtPath(path, zipInfo: zipInfo, unzippedPath: unzippedPath)
        }
    }

    func finishDidUnzipAtPath(_ path: String, zipInfo: unz_global_info, unzippedPath: String) async {
        if FileManager.default.isDeletableFile(atPath: path) {
            do {
                 try FileManager.default.removeItem(atPath: path)
            } catch {
                MageLogger.misc.error("Error removing file at path: %@", error.localizedDescription)
            }
        }
        
        let cacheOverlays = CacheOverlays.getInstance()
        await cacheOverlays.removeProcessing((path as NSString).lastPathComponent)
        
        // There is no way to know what was in the zip that was unarchived, so just add all current caches to the list
        let caches = try? FileManager.default.contentsOfDirectory(atPath: unzippedPath)
        for cache in caches ?? [] {
            let cacheDirectory = (unzippedPath as NSString).appendingPathComponent(cache)
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: cacheDirectory, isDirectory: &isDirectory)
            if exists && isDirectory.boolValue {
                let cacheOverlay = XYZDirectoryCacheOverlay(name: cache, directory: cacheDirectory)
                await cacheOverlays.add([cacheOverlay])
                MageLogger.misc.debug("Imported local XYZ Zip")
                
                _ = await layerRepository.createLoadedXYZLayer(name: cache)
            }
        }
    }
}
