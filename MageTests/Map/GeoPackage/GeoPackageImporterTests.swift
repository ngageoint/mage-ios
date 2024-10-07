//
//  GeoPackageImporterTests.swift
//  MAGETests
//
//  Created by Dan Barela on 9/27/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble
import geopackage_ios

@testable import MAGE

final class GeoPackageImporterTests: MageCoreDataTestCase {
    
    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    
    override func tearDown() async throws {
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
        await CacheOverlays.getInstance().removeAll()
        for subview in await view.subviews {
            await subview.removeFromSuperview();
        }
        waitUntil { done in
            self.controller.dismiss(animated: false, completion: {
                done();
            });
        }
        
        window.rootViewController = nil;
        navController = nil;
        view = nil;
        window = nil;
        
        try await super.tearDown()
    }
    
    override func setUp() async throws {
        try await super.setUp()
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
        await CacheOverlays.getInstance().removeAll()
        
        if (navController != nil) {
            waitUntil { done in
                self.navController.dismiss(animated: false, completion: {
                    done();
                });
            }
        }
        if (view != nil) {
            for subview in view.subviews {
                subview.removeFromSuperview();
            }
        }
        window = TestHelpers.getKeyWindowVisible();
        
        controller = UIViewController()
        navController = UINavigationController(rootViewController: controller);
        view = window
    }
    
    func testImportGeoPackageFileAndIndex() async throws {
        let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = documentsPaths[0] as String

        let countriesGeoPackagePath = URL(fileURLWithPath: "\(documentsDirectory)/countries2.gpkg")

        if FileManager.default.isDeletableFile(atPath: countriesGeoPackagePath.path) {
            do {
                try FileManager.default.removeItem(atPath: countriesGeoPackagePath.path)
            } catch {
                print("XXX error \(error)")
            }
        }

        try FileManager.default.createDirectory(at: countriesGeoPackagePath.deletingLastPathComponent(), withIntermediateDirectories: true)

        let stubPath = OHPathForFile("countries.gpkg", GeoPackageImporterTests.self)!

        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: countriesGeoPackagePath)
        
        let manager = GPKGGeoPackageFactory.manager()!
        NSLog("Countries GeoPackage path \(countriesGeoPackagePath.absoluteString)")
        
        if !manager.exists("countries2") {
            manager.importGeoPackage(fromPath: countriesGeoPackagePath.path())
        }
        
        let geoPackage = manager.open("countries2")!
        for featureTable in geoPackage.featureTables() {
            let featureDao = geoPackage.featureDao(withTableName: featureTable)!
            let index = GPKGFeatureTableIndex(geoPackage: geoPackage, andFeatureDao: featureDao)!
            if index.isIndexed() {
                let deleted = index.deleteIndex()
                print("XXX dleted index? \(deleted)")
                print("XXX is it still index? \(index.isIndexed())")
            } else {
                print("XXX not indexed")
            }
        }
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: "\(documentsDirectory)/2"), withIntermediateDirectories: true)
        manager.exportGeoPackage("countries2", toDirectory: "\(documentsDirectory)/2")
        geoPackage.close()

        if FileManager.default.isDeletableFile(atPath: countriesGeoPackagePath.path) {
            do {
                try FileManager.default.removeItem(atPath: countriesGeoPackagePath.path)
            } catch {
                print("XXX error \(error)")
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

        XCTAssertEqual(self.context.fetchAll(Layer.self)?.count, 1)
        XCTAssertEqual(self.context.fetchFirst(Layer.self, key: "eventId", value: -1)?.loaded, NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED))

        // verify that the geopackage was indexed
        let indexGP = manager.open("countries2")!
        for featureTable in indexGP.featureTables() {
            let featureDao = indexGP.featureDao(withTableName: featureTable)!
            let index = GPKGFeatureTableIndex(geoPackage: indexGP, andFeatureDao: featureDao)!
            XCTAssertTrue(index.isIndexed())
        }

        print("XXXX CLEAN UP THE THINGS")
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)

        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        XCTAssertEqual(self.context.fetchAll(Layer.self)?.count, 0)
    }

    func testImportGeoPackageFile() async throws {
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

        await fulfillment(of: [importExpectation])
    }
    
    func testImportGeoPackageFileIntoLayer() async throws {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
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
        
        await fulfillment(of: [importExpectation])
        
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 0)
    }
    
    func testImportGeoPackageFileIntoCurrentEventLayer() async throws {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        Server.setCurrentEventId(1)
                
        context.performAndWait {
            let layer = Layer(context: context)
            layer.remoteId = 1
            layer.name = "gpkgWithMedia_1_from_server"
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
        
        await fulfillment(of: [importExpectation])
        
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
    }
    
    func testFailImportGeoPackageFileIntoCurrentEventLayer() async throws {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        Server.setCurrentEventId(1)
        
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
        
        var urlPath = URL(fileURLWithPath: "\(documentsDirectory)/geopackages/1/icon27.png")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path).png")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {}
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let importer = GeoPackageImporter()
        let stubPath = OHPathForFile("icon27.png", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)
        
        await awaitDidSave {
            let imported = await importer.importGeoPackageFileAsLink(urlPath.path(), andMove: false, withLayerId: 1)
            
            XCTAssertFalse(imported)
            XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 0)
        }
        
        XCTAssertEqual(self.context.fetchFirst(Layer.self, key: "remoteId", value: 1)?.loaded, NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED))
    }
    
    func testImportGeoPackageTilesFileIntoLayer() async throws {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        Server.setCurrentEventId(1)
        
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
                "relativePath": "1/slateTiles4326.gpkg"
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
            } catch {
                print("XXX error \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let importer = GeoPackageImporter()
        let stubPath = OHPathForFile("slateTiles4326.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)
        
        let importExpectation = expectation(forNotification: .GeoPackageImported, object: nil)
        let imported = await importer.importGeoPackageFileAsLink(urlPath.path(), andMove: false, withLayerId: 1)
        XCTAssertTrue(imported)

        await fulfillment(of: [importExpectation])
        
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
    }
    
    func testHandleGeoPackageImport() async throws {
        let downloadPaths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)
        let downloadsDirectory = downloadPaths[0] as String
        
        var urlPath = URL(fileURLWithPath: "\(downloadsDirectory)/geopackages/1/slateTiles4326.gpkg")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path)_1_from_server.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {
                print("XXX error \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("slateTiles4326.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)

        let importer = GeoPackageImporter()
        await awaitDidSave {
            let imported = await importer.handleGeoPackageImport(urlPath.path())
            
            XCTAssertTrue(imported)
        }
        
        context.performAndWait {
            let layers = self.context.fetchAll(Layer.self)
            XCTAssertEqual(layers?.count, 1)
        }
        XCTAssertEqual(self.context.fetchFirst(Layer.self, key: "eventId", value: -1)?.loaded, NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED))
        
        print("XXXX CLEAN UP THE THINGS")
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        XCTAssertEqual(self.context.fetchAll(Layer.self)?.count, 0)
    }
    
    func testHandleGeoPackageImportDropIn() async throws {
        let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = documentsPaths[0] as String
        
        var urlPath = URL(fileURLWithPath: "\(documentsDirectory)/slateTiles4326.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {
                print("XXX error \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("slateTiles4326.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)

        let importer = GeoPackageImporter()
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
                
        context.performAndWait {
            let layers = self.context.fetchAll(Layer.self)
            XCTAssertEqual(layers?.count, 1)
        }
        XCTAssertEqual(self.context.fetchFirst(Layer.self, key: "eventId", value: -1)?.loaded, NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED))
        
        print("XXXX CLEAN UP THE THINGS")
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        XCTAssertEqual(self.context.fetchAll(Layer.self)?.count, 0)
    }
    
    func testHandleGeoPackageImportDeleteFile() async throws {
        let downloadPaths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)
        let downloadsDirectory = downloadPaths[0] as String
        
        var urlPath = URL(fileURLWithPath: "\(downloadsDirectory)/geopackages/1/slateTiles4326.gpkg")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path)_1_from_server.gpkg")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {
                print("XXX error \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("slateTiles4326.gpkg", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)

        let importer = GeoPackageImporter()
        await awaitDidSave {
            let imported = await importer.handleGeoPackageImport(urlPath.path())
            
            XCTAssertTrue(imported)
        }
        
        context.performAndWait {
            let layers = self.context.fetchAll(Layer.self)
            XCTAssertEqual(layers?.count, 1)
        }
        XCTAssertEqual(self.context.fetchFirst(Layer.self, key: "eventId", value: -1)?.loaded, NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED))
        
        print("XXXX CLEAN UP THE THINGS")
        
        let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentPath = documentPaths[0] as String
        
        var gpPath = URL(fileURLWithPath: "\(documentPath)/geopackage/db/slateTiles4326_1_from_server.gpkg")
        do {
            try FileManager.default.removeItem(atPath: gpPath.path)
        } catch {
            print("XXX error \(error)")
        }
        
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        XCTAssertEqual(self.context.fetchAll(Layer.self)?.count, 0)
    }
    
    func testNotAGeoPackage() async throws {
        let downloadPaths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)
        let downloadsDirectory = downloadPaths[0] as String
        
        var urlPath = URL(fileURLWithPath: "\(downloadsDirectory)/geopackages/1/icon27.png")
        urlPath = URL(fileURLWithPath: "\(urlPath.deletingPathExtension().path).png")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {
                print("XXX error \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("icon27.png", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)

        let importer = GeoPackageImporter()
        let imported = await importer.handleGeoPackageImport(urlPath.path())
        
        XCTAssertFalse(imported)
        
        context.performAndWait {
            let layers = self.context.fetchAll(Layer.self)
            XCTAssertEqual(layers?.count, 0)
        }
    }
    
    func testProcessOfflineMapArchivesXYZZip() async throws {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = documentsPaths[0] as String
        
        let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "\(documentsDirectory)"),
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles)
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        
        var urlPath = URL(fileURLWithPath: "\(documentsDirectory)/000Tile.zip")
        
        if FileManager.default.isDeletableFile(atPath: urlPath.path) {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {
                print("XXX error \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("000Tile.zip", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)

        let importer = GeoPackageImporter()
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
                
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        context.performAndWait {
            XCTAssertEqual(self.context.fetchAll(Layer.self)?.count, 1)

            let layer = self.context.fetchAll(Layer.self)?.first
            expect(layer?.loaded).to(equal(NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED)))
            expect(layer?.type).to(equal("Local_XYZ"))
            expect(layer?.name).to(equal("0"))
            expect(layer?.eventId).to(equal(-1))
            
            let overlay = CacheOverlays.getInstance().getByCacheName("0")
            expect(overlay).toNot(beNil())
        }
        
        let fileURLs2 = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "\(documentsDirectory)"),
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles)
        for fileURL in fileURLs2 {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        await CacheOverlays.getInstance().remove(byCacheName: "0")
        
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        XCTAssertEqual(self.context.fetchAll(Layer.self)?.count, 0)
    }
    
    func testProcessOfflineMapArchivesXYZDirectory() async throws {
        let mockListener = MockCacheOverlayListener()
        await CacheOverlays.getInstance().register(mockListener)
        
        let documentsPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = documentsPaths[0] as String
        
        let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "\(documentsDirectory)"),
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles)
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        let urlPath = URL(fileURLWithPath: "\(documentsDirectory)/MapCache/testxyz/0/0/0.png")
        
        if FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/MapCache/testxyz") {
            do {
                try FileManager.default.removeItem(atPath: urlPath.path)
            } catch {
                print("XXX error \(error)")
            }
        }
        
        try FileManager.default.createDirectory(at: urlPath.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let stubPath = OHPathForFile("tile.png", GeoPackageImporterTests.self)!
        
        try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)

        let importer = GeoPackageImporter()
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
                
        XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
        
        context.performAndWait {
            XCTAssertEqual(self.context.fetchAll(Layer.self)?.count, 1)

            let layer = self.context.fetchAll(Layer.self)?.first
            expect(layer?.loaded).to(equal(NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED)))
            expect(layer?.type).to(equal("Local_XYZ"))
            expect(layer?.name).to(equal("testxyz"))
        }
        let fileURLs2 = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "\(documentsDirectory)"),
                                                                   includingPropertiesForKeys: nil,
                                                                   options: .skipsHiddenFiles)
        for fileURL in fileURLs2 {
            try FileManager.default.removeItem(at: fileURL)
        }
        
        await CacheOverlays.getInstance().remove(byCacheName: "testxyz")
        
        await awaitDidSave {
            await importer.processOfflineMapArchives()
        }
        
        XCTAssertEqual(self.context.fetchAll(Layer.self)?.count, 0)
    }
}
