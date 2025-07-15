//
//  GeoPackageTests.swift
//  MAGETests
//
//  Created by Dan Barela on 10/7/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import OHHTTPStubs
import GeoPackage
import OSLog

@testable import MAGE

final class GeoPackageTests: MageCoreDataTestCase {
    
    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    var mapView: MKMapView!
    
    override func setUp() async throws {
        try await super.setUp()
        
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
        await CacheOverlays.getInstance().removeAll()
        
        if (navController != nil) {
            await navController.dismiss(animated: false)
        }
        if (view != nil) {
            for subview in await view.subviews {
                await subview.removeFromSuperview();
            }
        }
        window = await TestHelpers.getKeyWindowVisibleMainActor();
        
        controller = await UIViewController()
        
        await setMapView()
        
        navController = await UINavigationController(rootViewController: controller);
        await setRootViewController(vc: navController)
        view = window
    }
    
    @MainActor
    func setMapView() {
        mapView = MKMapView()
        controller.view = mapView
    }
    
    @MainActor
    func setRootViewController(vc: UIViewController?) {
        window.rootViewController = vc
    }
    
    @MainActor
    func getMapOverlays() -> [any MKOverlay] {
        mapView.overlays
    }
    
    @MainActor
    func getAnnotations() -> [any MKAnnotation] {
        mapView.annotations
    }
    
    override func tearDown() async throws {
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
        await CacheOverlays.getInstance().removeAll()
        
        for subview in await view.subviews {
            await subview.removeFromSuperview();
        }
        await controller.dismiss(animated: false)
        
        await setRootViewController(vc: nil)
        navController = nil;
        view = nil;
        window = nil;
        try await super.tearDown()
    }
    
    func testInit() {
        let geoPackage = GeoPackage(mapView: mapView)
        
        XCTAssertNotNil(geoPackage)
    }
    
    @MainActor
    func testAddGeoPackageLayer() async throws {
        
        UserDefaults.standard.selectedCaches = ["gpkgWithMedia_1_from_server"]
        
        context.performAndWait {
            let layer = Layer(context: context)
            layer.remoteId = 1
            layer.name = "name"
            layer.type = "GeoPackage"
            layer.eventId = 1
            layer.file = [
                "name": "gpkgWithMedia.gpkg",
                "contentType":"application/octet-stream",
                "size": "2859008",
                "relativePath": "1/geopackageabc.gpkg"
            ]
            layer.layerDescription = "description"
            
            try? context.obtainPermanentIDs(for: [layer])
            try? context.save()
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        var urlPath = URL(fileURLWithPath: "\(documentsDirectory)/geopackages/1/gpkgWithMedia.gpkg")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path)_1_from_server.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {}
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let importer = GeoPackageImporter()
        let stubPath = OHPathForFile("gpkgWithMedia.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)
        
        let importExpectation = expectation(forNotification: .GeoPackageImported, object: nil)
        
        _ = await importer.importGeoPackageFileAsLink(urlPath.path(), andMove: false, withLayerId: 1)
        
        await fulfillment(of: [importExpectation], timeout: 2)
        
        Server.setCurrentEventId(1)
        
        let geoPackage = GeoPackage(mapView: mapView)
        await geoPackage.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())
        
        let predicateExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            return self.getMapOverlays().count == 1
        }), object: nil)
        await fulfillment(of: [predicateExpectation], timeout: 5)
        
        let overlays = getMapOverlays()
        let annotations = getAnnotations()
        XCTAssertEqual(overlays.count, 1)
        XCTAssertEqual(annotations.count, 0)
    }
    
    @MainActor
    func testUnselectGeoPackageLayer() async throws {
        
        UserDefaults.standard.selectedCaches = ["gpkgWithMedia_1_from_server"]
        
        context.performAndWait {
            let layer = Layer(context: context)
            layer.remoteId = 1
            layer.name = "name"
            layer.type = "GeoPackage"
            layer.eventId = 1
            layer.file = [
                "name": "gpkgWithMedia.gpkg",
                "contentType":"application/octet-stream",
                "size": "2859008",
                "relativePath": "1/geopackageabc.gpkg"
            ]
            layer.layerDescription = "description"
            
            try? context.obtainPermanentIDs(for: [layer])
            try? context.save()
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        var urlPath = URL(fileURLWithPath: "\(documentsDirectory)/geopackages/1/gpkgWithMedia.gpkg")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path)_1_from_server.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {}
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let importer = GeoPackageImporter()
        let stubPath = OHPathForFile("gpkgWithMedia.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)
        
        let importExpectation = expectation(forNotification: .GeoPackageImported, object: nil)
        
        _ = await importer.importGeoPackageFileAsLink(urlPath.path(), andMove: false, withLayerId: 1)
        
        await fulfillment(of: [importExpectation], timeout: 2)
        
        Server.setCurrentEventId(1)
        
        let geoPackage = GeoPackage(mapView: mapView)
        await geoPackage.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())
        
        let predicateExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            return self.getMapOverlays().count == 1
        }), object: nil)
        await fulfillment(of: [predicateExpectation], timeout: 5)
        
        let overlays = getMapOverlays()
        let annotations = getAnnotations()
        XCTAssertEqual(overlays.count, 1)
        XCTAssertEqual(annotations.count, 0)
        
        UserDefaults.standard.selectedCaches = []
        let cacheOverlay = await CacheOverlays.getInstance().getByCacheName("gpkgWithMedia_1_from_server")!
        cacheOverlay.enabled = false
        await CacheOverlays.getInstance().addCacheOverlay(overlay: cacheOverlay)
        await geoPackage.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())
        
        let predicateExpectation2 = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            return self.getMapOverlays().count == 0
        }), object: nil)
        await fulfillment(of: [predicateExpectation2], timeout: 5)
        
        let overlays2 = getMapOverlays()
        let annotations2 = getAnnotations()
        XCTAssertEqual(overlays2.count, 0)
        XCTAssertEqual(annotations2.count, 0)
    }
    
    @MainActor
    func testAddGeoPackageFeatureLayer() async throws {
        UserDefaults.standard.geoPackageFeaturesMaxFeaturesPerTable = 1000000
        UserDefaults.standard.selectedCaches = ["countries2"]
        
        let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = documentsPaths[0] as String
        
        let countriesGeoPackagePath = URL(fileURLWithPath: "\(documentsDirectory)/countries2.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: countriesGeoPackagePath.path) {
            do {
                try FileManager.default.removeItem(atPath: countriesGeoPackagePath.path)
            } catch {
                os_log("Error: \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: countriesGeoPackagePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("countries.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: countriesGeoPackagePath)
        
        let manager = GPKGGeoPackageFactory.manager()!
        os_log("Countries GeoPackage path \(countriesGeoPackagePath.absoluteString)")
        
        if !manager.exists("countries2") {
            manager.importGeoPackage(fromPath: countriesGeoPackagePath.path())
        }
        
        let geoPackage = manager.open("countries2")!
        for featureTable in geoPackage.featureTables() {
            let featureDao = geoPackage.featureDao(withTableName: featureTable)!
            let index = GPKGFeatureTableIndex(geoPackage: geoPackage, andFeatureDao: featureDao)!
            if index.isIndexed() {
                let deleted = index.deleteIndex()
            }
        }
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: "\(documentsDirectory)/2"), withIntermediateDirectories: true)
        manager.exportGeoPackage("countries2", toDirectory: "\(documentsDirectory)/2")
        geoPackage.close()
        
        if FileManager.default.isDeletableFile(atPath: countriesGeoPackagePath.path) {
            do {
                try FileManager.default.removeItem(atPath: countriesGeoPackagePath.path)
            } catch {
                os_log("Error: \(error)")
            }
        }
        let countriesGeoPackagePath2 = URL(fileURLWithPath: "\(documentsDirectory)/2/countries2.gpkg")
        try FileManager.default.copyItem(at: countriesGeoPackagePath2, to: countriesGeoPackagePath)
        
        let fileExists = FileManager.default.fileExists(atPath: countriesGeoPackagePath.path())
        XCTAssertTrue(fileExists)
        
        manager.delete("countries2")
        
        let importer = GeoPackageImporter()
        
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        Server.setCurrentEventId(1)
        
        let geoPackageClass = GeoPackage(mapView: mapView)
        let cacheOverlays = await CacheOverlays.getInstance().getOverlays()
        var newOverlays: [CacheOverlay] = []
        for overlay in cacheOverlays {
            if let overlay = overlay as? GeoPackageCacheOverlay {
                let children = overlay.getChildren()
                var newChildren: [GeoPackageTableCacheOverlay] = []
                for child in children {
                    if let childOverlay = child as? GeoPackageFeatureTableCacheOverlay {
                        let newChildOverlay = GeoPackageFeatureTableCacheOverlay(
                            name: childOverlay.name,
                            geoPackage: childOverlay.geoPackage,
                            cacheName: childOverlay.cacheName,
                            count: childOverlay.count,
                            minZoom: childOverlay.minZoom,
                            indexed: false,
                            geometryType: childOverlay.geometryType
                        )
                        newChildOverlay.enabled = true
                        newChildren.append(newChildOverlay)
                    }
                }
                
                let newOverlay = GeoPackageCacheOverlay(
                    name: overlay.name,
                    path: overlay.filePath,
                    tables: newChildren
                )
                newOverlay.enabled = true
                newOverlay.added = true
                newOverlays.append(newOverlay)
            }
        }
        
        await geoPackageClass.updateCacheOverlaysSynchronized(newOverlays)
        
        let predicateExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            let count = self.getAnnotations().count
            let overlayCount = self.getMapOverlays().count
            return overlayCount == 1405
        }), object: nil)
        await fulfillment(of: [predicateExpectation], timeout: 5)
        
        let overlays = getMapOverlays()
        let annotations = getAnnotations()
        XCTAssertEqual(overlays.count, 1405)
        XCTAssertEqual(annotations.count, 0)
        
        let predicateExpectation2 = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            let centerCoordinate = self.mapView.centerCoordinate
            return Int(centerCoordinate.longitude) == 0 && Int(centerCoordinate.latitude) == 0
        }), object: nil)
        await fulfillment(of: [predicateExpectation2], timeout: 5)
    }
    
    @MainActor
    func testAddGeoPackageFeatureLayerLimitFeatures() async throws {
        UserDefaults.standard.geoPackageFeaturesMaxFeaturesPerTable = 5
        UserDefaults.standard.selectedCaches = ["countries2"]
        
        let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = documentsPaths[0] as String
        
        let countriesGeoPackagePath = URL(fileURLWithPath: "\(documentsDirectory)/countries2.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: countriesGeoPackagePath.path) {
            do {
                try FileManager.default.removeItem(atPath: countriesGeoPackagePath.path)
            } catch {
                os_log("Error: \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: countriesGeoPackagePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("countries.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: countriesGeoPackagePath)
        
        let manager = GPKGGeoPackageFactory.manager()!
        os_log("Countries GeoPackage path \(countriesGeoPackagePath.absoluteString)")
        
        if !manager.exists("countries2") {
            manager.importGeoPackage(fromPath: countriesGeoPackagePath.path())
        }
        
        let geoPackage = manager.open("countries2")!
        for featureTable in geoPackage.featureTables() {
            let featureDao = geoPackage.featureDao(withTableName: featureTable)!
            let index = GPKGFeatureTableIndex(geoPackage: geoPackage, andFeatureDao: featureDao)!
            if index.isIndexed() {
                let deleted = index.deleteIndex()
            }
        }
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: "\(documentsDirectory)/2"), withIntermediateDirectories: true)
        manager.exportGeoPackage("countries2", toDirectory: "\(documentsDirectory)/2")
        geoPackage.close()
        
        if FileManager.default.isDeletableFile(atPath: countriesGeoPackagePath.path) {
            do {
                try FileManager.default.removeItem(atPath: countriesGeoPackagePath.path)
            } catch {
                os_log("Error: \(error)")
            }
        }
        let countriesGeoPackagePath2 = URL(fileURLWithPath: "\(documentsDirectory)/2/countries2.gpkg")
        try FileManager.default.copyItem(at: countriesGeoPackagePath2, to: countriesGeoPackagePath)
        
        let fileExists = FileManager.default.fileExists(atPath: countriesGeoPackagePath.path())
        XCTAssertTrue(fileExists)
        
        manager.delete("countries2")
        
        let importer = GeoPackageImporter()
        
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        Server.setCurrentEventId(1)
        
        let geoPackageClass = GeoPackage(mapView: mapView)
        let cacheOverlays = await CacheOverlays.getInstance().getOverlays()
        var newOverlays: [CacheOverlay] = []
        for overlay in cacheOverlays {
            if let overlay = overlay as? GeoPackageCacheOverlay {
                let children = overlay.getChildren()
                var newChildren: [GeoPackageTableCacheOverlay] = []
                for child in children {
                    if let childOverlay = child as? GeoPackageFeatureTableCacheOverlay {
                        let newChildOverlay = GeoPackageFeatureTableCacheOverlay(
                            name: childOverlay.name,
                            geoPackage: childOverlay.geoPackage,
                            cacheName: childOverlay.cacheName,
                            count: childOverlay.count,
                            minZoom: childOverlay.minZoom,
                            indexed: false,
                            geometryType: childOverlay.geometryType
                        )
                        newChildOverlay.enabled = true
                        newChildren.append(newChildOverlay)
                    }
                }
                
                let newOverlay = GeoPackageCacheOverlay(
                    name: overlay.name,
                    path: overlay.filePath,
                    tables: newChildren
                )
                newOverlay.enabled = true
                newOverlays.append(newOverlay)
            }
        }
        
        await geoPackageClass.updateCacheOverlaysSynchronized(newOverlays)
        
        let predicateExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            let count = self.getAnnotations().count
            let overlayCount = self.getMapOverlays().count
            return overlayCount == 5
        }), object: nil)
        await fulfillment(of: [predicateExpectation], timeout: 5)
        
        let overlays = getMapOverlays()
        let annotations = getAnnotations()
        XCTAssertEqual(overlays.count, 5)
        XCTAssertEqual(annotations.count, 0)
    }
    
    
    @MainActor
    func testReplaceGeoPackageLayer() async throws {
        
        UserDefaults.standard.selectedCaches = ["gpkgWithMedia_1_from_server"]
        
        context.performAndWait {
            let layer = Layer(context: context)
            layer.remoteId = 1
            layer.name = "name"
            layer.type = "GeoPackage"
            layer.eventId = 1
            layer.file = [
                "name": "gpkgWithMedia.gpkg",
                "contentType":"application/octet-stream",
                "size": "2859008",
                "relativePath": "1/geopackageabc.gpkg"
            ]
            layer.layerDescription = "description"
            
            try? context.obtainPermanentIDs(for: [layer])
            try? context.save()
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        var urlPath = URL(fileURLWithPath: "\(documentsDirectory)/geopackages/1/gpkgWithMedia.gpkg")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path)_1_from_server.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {}
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let importer = GeoPackageImporter()
        let stubPath = OHPathForFile("gpkgWithMedia.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)
        
        let importExpectation = expectation(forNotification: .GeoPackageImported, object: nil)
        
        _ = await importer.importGeoPackageFileAsLink(urlPath.path(), andMove: false, withLayerId: 1)
        
        await fulfillment(of: [importExpectation], timeout: 2)
        
        Server.setCurrentEventId(1)
        
        let geoPackage = GeoPackage(mapView: mapView)
        await geoPackage.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())
        
        let predicateExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            return self.getMapOverlays().count == 1
        }), object: nil)
        await fulfillment(of: [predicateExpectation], timeout: 5)
        
        let overlays = getMapOverlays()
        let annotations = getAnnotations()
        XCTAssertEqual(overlays.count, 1)
        XCTAssertEqual(annotations.count, 0)
        
        let cacheOverlays = await CacheOverlays.getInstance().getOverlays()
        
        let initialOverlay = await CacheOverlays.getInstance().getOverlays()[0]
        let initialGeoPackageOverlay = overlays[0]

        var newOverlays: [CacheOverlay] = []
        if let overlay = initialOverlay as? GeoPackageCacheOverlay {
            let children = overlay.getChildren()
            var newChildren: [GeoPackageTableCacheOverlay] = []
            for child in children {
                if let childOverlay = child as? GeoPackageFeatureTableCacheOverlay {
                    let newChildOverlay = GeoPackageFeatureTableCacheOverlay(
                        name: childOverlay.name,
                        geoPackage: childOverlay.geoPackage,
                        cacheName: childOverlay.cacheName,
                        count: childOverlay.count,
                        minZoom: childOverlay.minZoom,
                        indexed: true,
                        geometryType: childOverlay.geometryType
                    )
                    newChildOverlay.enabled = true
                    newChildren.append(newChildOverlay)
                }
            }
            
            let newOverlay = GeoPackageCacheOverlay(
                name: overlay.name,
                path: overlay.filePath,
                tables: newChildren
            )
            newOverlay.enabled = true
            newOverlay.replaced = initialOverlay
            newOverlays.append(newOverlay)
        }
        
        await geoPackage.updateCacheOverlaysSynchronized(newOverlays)
        
        let predicateExpectation2 = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            let overlays = self.getMapOverlays()
            return overlays[0] as? GPKGFeatureOverlay != initialGeoPackageOverlay as? GPKGFeatureOverlay
        }), object: nil)
        await fulfillment(of: [predicateExpectation2], timeout: 5)
        
        let overlays2 = getMapOverlays()
        let annotations2 = getAnnotations()
        XCTAssertEqual(overlays2.count, 1)
        XCTAssertEqual(annotations2.count, 0)
    }
    
    @MainActor
    func testXYZLayer() async throws {
        UserDefaults.standard.selectedCaches = ["0"]
        
        let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = documentsPaths[0] as String
        
        let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "\(documentsDirectory)"),
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles)
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        
        let urlPath = URL(fileURLWithPath: "\(documentsDirectory)/000Tile.zip")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {
                os_log("Error: \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("000Tile.zip", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)

        let importer = GeoPackageImporter()
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        let cacheOverlays = await CacheOverlays.getInstance().getOverlays()
        let overlay = cacheOverlays[0]
        overlay.enabled = true
        await CacheOverlays.getInstance().addCacheOverlay(overlay: overlay)
        
        let geoPackage = GeoPackage(mapView: mapView)
        await geoPackage.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())
        
        let predicateExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            return self.getMapOverlays().count == 1
        }), object: nil)
        await fulfillment(of: [predicateExpectation], timeout: 5)

        let overlays = getMapOverlays()
        let annotations = getAnnotations()
        XCTAssertEqual(overlays.count, 1)
        XCTAssertEqual(annotations.count, 0)
    }
    
    @MainActor
    func testAddGeoPackageTileLayer() async throws {
        
        UserDefaults.standard.selectedCaches = ["slateTiles4326_1_from_server"]
        
        context.performAndWait {
            let layer = Layer(context: context)
            layer.remoteId = 1
            layer.name = "name"
            layer.type = "GeoPackage"
            layer.eventId = 1
            layer.file = [
                "name": "slateTiles4326.gpkg",
                "contentType":"application/octet-stream",
                "size": "2859008",
                "relativePath": "1/geopackageabc.gpkg"
            ]
            layer.layerDescription = "description"
            
            try? context.obtainPermanentIDs(for: [layer])
            try? context.save()
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        var urlPath = URL(fileURLWithPath: "\(documentsDirectory)/geopackages/1/slateTiles4326.gpkg")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path)_1_from_server.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {}
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let importer = GeoPackageImporter()
        let stubPath = OHPathForFile("slateTiles4326.gpkg", GeoPackageTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)
        
        let importExpectation = expectation(forNotification: .GeoPackageImported, object: nil)
        
        _ = await importer.importGeoPackageFileAsLink(urlPath.path(), andMove: false, withLayerId: 1)
        
        await fulfillment(of: [importExpectation], timeout: 2)
        
        Server.setCurrentEventId(1)
        
        let geoPackage = GeoPackage(mapView: mapView)
        await geoPackage.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())
        
        let predicateExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            return self.getMapOverlays().count == 1
        }), object: nil)
        await fulfillment(of: [predicateExpectation], timeout: 5)
        
        let overlays = getMapOverlays()
        let annotations = getAnnotations()
        XCTAssertEqual(overlays.count, 1)
        XCTAssertEqual(annotations.count, 0)
        let initialOverlay = await CacheOverlays.getInstance().getOverlays()[0]
        let initialGeoPackageOverlay = overlays[0]

        var newOverlays: [CacheOverlay] = []
        if let overlay = initialOverlay as? GeoPackageCacheOverlay {
            let children = overlay.getChildren() ?? []
            var newChildren: [GeoPackageTableCacheOverlay] = []
            for child in children {
                if let childOverlay = child as? GeoPackageTileTableCacheOverlay {
                    let newChildOverlay = GeoPackageTileTableCacheOverlay(
                        name: childOverlay.name,
                        geoPackage: childOverlay.geoPackage,
                        cacheName: childOverlay.cacheName,
                        count: childOverlay.count,
                        minZoom: childOverlay.minZoom,
                        maxZoom: childOverlay.maxZoom
                    )
                    newChildOverlay.enabled = true
                    newChildren.append(newChildOverlay)
                }
            }

            let newOverlay = GeoPackageCacheOverlay(
                name: overlay.name,
                path: overlay.filePath,
                tables: newChildren
            )
            newOverlay.enabled = true
            newOverlay.replaced = initialOverlay
            newOverlays.append(newOverlay)
        }

        await geoPackage.updateCacheOverlaysSynchronized(newOverlays)

        let predicateExpectation2 = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            let overlays = self.getMapOverlays()
            return overlays[0] as? GPKGBoundedOverlay != initialGeoPackageOverlay as? GPKGBoundedOverlay
        }), object: nil)
        await fulfillment(of: [predicateExpectation2], timeout: 5)

        let overlays2 = getMapOverlays()
        let annotations2 = getAnnotations()
        XCTAssertEqual(overlays2.count, 1)
        XCTAssertEqual(annotations2.count, 0)
    }
    
    // TODO: Fails
    @MainActor
    func testAddGeoPackageTileLayerThenReAdd() async throws {
        
        UserDefaults.standard.selectedCaches = ["slateTiles4326_1_from_server"]
        
        context.performAndWait {
            let layer = Layer(context: context)
            layer.remoteId = 1
            layer.name = "name"
            layer.type = "GeoPackage"
            layer.eventId = 1
            layer.file = [
                "name": "slateTiles4326.gpkg",
                "contentType":"application/octet-stream",
                "size": "2859008",
                "relativePath": "1/geopackageabc.gpkg"
            ]
            layer.layerDescription = "description"
            
            try? context.obtainPermanentIDs(for: [layer])
            try? context.save()
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        var urlPath = URL(fileURLWithPath: "\(documentsDirectory)/geopackages/1/slateTiles4326.gpkg")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path)_1_from_server.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {}
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let importer = GeoPackageImporter()
        let stubPath = OHPathForFile("slateTiles4326.gpkg", GeoPackageTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)
        
        let importExpectation = expectation(forNotification: .GeoPackageImported, object: nil)
        
        _ = await importer.importGeoPackageFileAsLink(urlPath.path(), andMove: false, withLayerId: 1)
        
        await fulfillment(of: [importExpectation], timeout: 2)
        
        Server.setCurrentEventId(1)
        
        let geoPackage = GeoPackage(mapView: mapView)
        await geoPackage.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())
        
        let predicateExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            return self.getMapOverlays().count == 1
        }), object: nil)
        await fulfillment(of: [predicateExpectation], timeout: 5)
        
        let overlays = getMapOverlays()
        let annotations = getAnnotations()
        XCTAssertEqual(overlays.count, 1)
        XCTAssertEqual(annotations.count, 0)
        let initialOverlay = await CacheOverlays.getInstance().getOverlays()[0]
        let initialGeoPackageOverlay = overlays[0]

        await geoPackage.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())

        let predicateExpectation2 = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            let overlays = self.getMapOverlays()
            return overlays[0] as? GPKGBoundedOverlay != initialGeoPackageOverlay as? GPKGBoundedOverlay
        }), object: nil)
        await fulfillment(of: [predicateExpectation2], timeout: 5)

        let overlays2 = getMapOverlays()
        let annotations2 = getAnnotations()
        XCTAssertEqual(overlays2.count, 1)
        XCTAssertEqual(annotations2.count, 0)
    }
    
    // TODO: FAILS. Looks like data leakage is causing it
    @MainActor
    func testGetFeatureKeys() async throws {
        UserDefaults.standard.geoPackageFeaturesMaxFeaturesPerTable = 1000000
        UserDefaults.standard.selectedCaches = ["countries2"]
        
        let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = documentsPaths[0] as String
        
        let countriesGeoPackagePath = URL(fileURLWithPath: "\(documentsDirectory)/countries2.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: countriesGeoPackagePath.path) {
            do {
                try FileManager.default.removeItem(atPath: countriesGeoPackagePath.path)
            } catch {
                os_log("Error: \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: countriesGeoPackagePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("countries.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: countriesGeoPackagePath)
        
        let importer = GeoPackageImporter()
        
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        Server.setCurrentEventId(1)
        let geoPackageClass = GeoPackage(mapView: mapView)
        await geoPackageClass.updateCacheOverlaysSynchronized(CacheOverlays.getInstance().getOverlays())
        
        let predicateExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            let count = self.getAnnotations().count
            let overlayCount = self.getMapOverlays().count
            return overlayCount == 1
        }), object: nil)
        await fulfillment(of: [predicateExpectation], timeout: 5)
        
        let overlays = getMapOverlays()
        let annotations = getAnnotations()
        XCTAssertEqual(overlays.count, 1)
        XCTAssertEqual(annotations.count, 0)
        
        let keys = await geoPackageClass.getFeatureKeys(atTap: CLLocationCoordinate2D(latitude: 39.0, longitude: -104.0))
        
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(keys.first?.featureId, 487)
    }
}
