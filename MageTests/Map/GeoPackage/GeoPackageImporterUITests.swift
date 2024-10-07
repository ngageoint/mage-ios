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

final class GeoPackageImporterUITests: KIFMageCoreDataTestCase {

    override func spec() {
        
        describe("GeoPackageLayerMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            
            beforeEach {
                GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
                
                Task {
                    await CacheOverlays.getInstance().removeAll()
                }
                
                if (navController != nil) {
                    waitUntil { done in
                        navController.dismiss(animated: false, completion: {
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
                window.rootViewController = navController
                view = window
            }
            
            afterEach {
                GPKGGeoPackageFactory.manager().deleteAllAndFiles(false)
                
                Task {
                    await CacheOverlays.getInstance().removeAll()
                }
                
                for subview in view.subviews {
                    subview.removeFromSuperview();
                }
                waitUntil { done in
                    controller.dismiss(animated: false, completion: {
                        done();
                    });
                }
                
                window.rootViewController = nil;
                navController = nil;
                view = nil;
                window = nil;
            }
            
            it("Should handle geopackage import twice do not import") {
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
            
            it("Should handle geopackage import twice import as new") {
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
                }
                
                tester().waitForView(withAccessibilityLabel: "Do Not Import")
                tester().waitForView(withAccessibilityLabel: "Import As New")
                tester().waitForView(withAccessibilityLabel: "Overwrite Existing GeoPackage")
                
                tester().tapView(withAccessibilityLabel: "Import As New")
                
                expect(mockListener.updatedOverlaysWithoutBase?.count).toEventually(equal(2))
                
                let layers = self.context.fetchAll(Layer.self)
                XCTAssertEqual(layers?.count, 2)
            }
        
        
            it("Should handle geopackage import twice overwrite") {
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
                    let layers1 = self.context.fetchAll(Layer.self)
                    XCTAssertEqual(layers1?.count, 1)
                    
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
    }
}
