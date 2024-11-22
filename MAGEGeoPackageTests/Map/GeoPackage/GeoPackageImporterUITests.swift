//
//  GeoPackageImporterUITests.swift
//  MAGETests
//
//  Created by Dan Barela on 10/1/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Nimble
import Quick
import geopackage_ios
import OHHTTPStubs

@testable import MAGE

final class GeoPackageImporterUITests: AsyncMageCoreDataTestCase {

    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    
    override func setUp() async throws {
        print("XXX setup")
        try await super.setUp()
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
//        Task {
            await CacheOverlays.getInstance().removeAll()
//        }
        
        await setupViews()
    }
    
    @MainActor
    func setupViews() {
        if (navController != nil) {
            navController.dismiss(animated: false);
        }
        if (view != nil) {
            for subview in view.subviews {
                subview.removeFromSuperview();
            }
        }
        window = TestHelpers.getKeyWindowVisible();
        
        controller = UIViewController()
        navController = UINavigationController(rootViewController: controller);
        window.rootViewController = navController
        view = window
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
        
//        Task {
            await CacheOverlays.getInstance().removeAll()
//        }
        
        await tearDownViews()
    }
    
    @MainActor
    func tearDownViews() {
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
        controller.dismiss(animated: false);
        
        window.rootViewController = nil;
        navController = nil;
        view = nil;
        window = nil;
    }
    
    func testShouldHandleGeoPackageImportTwiceDoNotImport() throws {
        XCTAssertEqual(1, 1)
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

        Task {
            let importer = GeoPackageImporter()
            let imported = await importer.handleGeoPackageImport(urlPath.path())
            
            XCTAssertTrue(imported)
            
            let importedAgain = await importer.handleGeoPackageImport(urlPath.path())
            
            XCTAssertFalse(importedAgain)
        }
        
        tester().waitForView(withAccessibilityLabel: "Do Not Import")
        tester().waitForView(withAccessibilityLabel: "Import As New")
        tester().waitForView(withAccessibilityLabel: "Overwrite Existing GeoPackage")
        
        tester().tapView(withAccessibilityLabel: "Do Not Import")
    }
    
    @MainActor
    func testShouldHandleGeoPackageImportTwiceImportAsNew() async throws {
        let mockListener = MockCacheOverlayListener()
        Task {
            await CacheOverlays.getInstance().register(mockListener)
        }
        
        Server.setCurrentEventId(1)
        
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
                        
//        Task {
            await self.awaitDidSave {
                let imported = await importer.handleGeoPackageImport(urlPath.path())
                
                XCTAssertTrue(imported)
            }
            XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
            let layers1 = self.context.fetchAll(Layer.self)
            XCTAssertEqual(layers1?.count, 1)
            
            try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)
            
            let importedAgain = await importer.handleGeoPackageImport(urlPath.path())
            
            XCTAssertFalse(importedAgain)
//        }
        
        tester().waitForView(withAccessibilityLabel: "Do Not Import")
        tester().waitForView(withAccessibilityLabel: "Import As New")
        tester().waitForView(withAccessibilityLabel: "Overwrite Existing GeoPackage")
        
        tester().tapView(withAccessibilityLabel: "Import As New")
        
        let predicate = NSPredicate { _, _ in
            return mockListener.updatedOverlaysWithoutBase?.count == 2
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [expectation], timeout: 2)
                
        let layers = self.context.fetchAll(Layer.self)
        XCTAssertEqual(layers?.count, 2)
    }

    @MainActor
    func testShouldHandleGeoPackageImportTwiceOverwrite() throws {
        let mockListener = MockCacheOverlayListener()
        Task {
            await CacheOverlays.getInstance().register(mockListener)
        }
        
        Server.setCurrentEventId(1)
        
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
                        
        Task {
            let imported = await importer.handleGeoPackageImport(urlPath.path())
            
            XCTAssertTrue(imported)
            XCTAssertEqual(mockListener.updatedOverlaysWithoutBase?.count, 1)
            self.context.performAndWait {
                let layers1 = self.context.fetchAll(Layer.self)
                XCTAssertEqual(layers1?.count, 1)
            }
            try FileManager.default.copyItem(at: URL(fileURLWithPath: stubPath), to: urlPath)
            
            let importedAgain = await importer.handleGeoPackageImport(urlPath.path())
            
            XCTAssertFalse(importedAgain)
        }
        
        tester().waitForView(withAccessibilityLabel: "Do Not Import")
        tester().waitForView(withAccessibilityLabel: "Import As New")
        tester().waitForView(withAccessibilityLabel: "Overwrite Existing GeoPackage")
        
        tester().tapView(withAccessibilityLabel: "Overwrite Existing GeoPackage")
        
        expect(mockListener.updatedOverlaysWithoutBase?.count).toEventually(equal(1))
        
        let layers = self.context.fetchAll(Layer.self)
        XCTAssertEqual(layers?.count, 1)
    }
}
