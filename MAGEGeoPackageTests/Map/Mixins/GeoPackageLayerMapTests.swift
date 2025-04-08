//
//  GeoPackageLayerMapTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/15/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import MagicalRecord
import OHHTTPStubs
import MapFramework

@testable import MAGE
import CoreLocation
import MapKit

class GeoPackageLayerMapTestImpl : NSObject, GeoPackageLayerMap {
    var mapView: MKMapView?
    
    var geoPackageLayerMapMixin: GeoPackageLayerMapMixin?
}

extension GeoPackageLayerMapTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return geoPackageLayerMapMixin?.renderer(overlay: overlay) ?? geoPackageLayerMapMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return geoPackageLayerMapMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class GeoPackageLayerMapTests: AsyncMageCoreDataTestCase {
    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    var testimpl: GeoPackageLayerMapTestImpl!
    var mixin: GeoPackageLayerMapMixin!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        if (navController != nil) {
            navController.dismiss(animated: false);
        }
        if (view != nil) {
            for subview in view.subviews {
                subview.removeFromSuperview();
            }
        }
        window = TestHelpers.getKeyWindowVisible();
        UserDefaults.standard.mapType = 0;
        UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
        
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.selectedStaticLayers = nil
        
        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
        
        Server.setCurrentEventId(1);
        
        controller = UIViewController()
        let mapView = MKMapView()
        controller.view = mapView
        
        testimpl = GeoPackageLayerMapTestImpl()
        testimpl.mapView = mapView
        mapView.delegate = testimpl
        
        navController = UINavigationController(rootViewController: controller);
        
        mixin = GeoPackageLayerMapMixin(geoPackageLayerMap: testimpl)
        testimpl.geoPackageLayerMapMixin = mixin
        window.rootViewController = navController;
        
        view = window
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    @MainActor
    override func tearDown() async throws {
        try await super.tearDown()
        mixin = nil
        testimpl = nil
        
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
        controller.dismiss(animated: false);
        UserDefaults.standard.selectedStaticLayers = nil
        UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
        
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .unspecified
        }
        window?.resignKey();
        window.rootViewController = nil;
        navController = nil;
        view = nil;
        window = nil;
    }
    
    // TODO: Failing test
    @MainActor
    func testInitializeTheStaticLayerMapWithANotLoadedLayerThenLoadItButDontAddItToTheMap() async {
        
        var stubCalled = XCTestExpectation(description: "Layers Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers")
        ) { (request) -> HTTPStubsResponse in
            stubCalled.fulfill()
            print("XXX returning thr response")
            return HTTPStubsResponse(jsonObject: [[
                LayerKey.id.key: 1,
                LayerKey.name.key: "name",
                LayerKey.state.key: "available",
                LayerKey.description.key: "description",
                LayerKey.type.key: "GeoPackage",
                LayerKey.tables.key: [[
                    "name":"Observations",
                    "type":"feature",
                    "bbox": [-180,90,180,90]
                ]],
                LayerKey.file.key: [
                    "name": "gpkgWithMedia.gpkg",
                    "contentType":"application/octet-stream",
                    "size": "2859008",
                    "relativePath": "1/geopackageabc.gpkg"
                ]
            ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var geopackageStubCalled = XCTestExpectation(description: "GeoPackage Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers/1")
        ) { (request) -> HTTPStubsResponse in
            geopackageStubCalled.fulfill()
            let stubPath = OHPathForFile("gpkgWithMedia.gpkg", GeoPackageLayerMapTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/octet-stream"]);
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
        
        await awaitDidSave {
            Layer.refreshLayers(eventId: 1);
        }
        
        await fulfillment(of: [stubCalled], timeout: 3)

        let layer = context.performAndWait {
            let layers = try? self.context.fetchObjects(Layer.self)
            expect(layers?.count).to(equal(1))
            let layer = try! context.fetchFirst(Layer.self)!;
            expect(layer.remoteId).to(equal(1))
            expect(layer.name).to(equal("name"))
            expect(layer.type).to(equal("GeoPackage"))
            expect(layer.eventId).to(equal(1))
            expect(layer.file).toNot(beNil());
            expect(layer.layerDescription).to(equal("description"))
            expect(layer.state).to(equal("available"))
            return layer
        }
        
        var successfulDownload = XCTestExpectation(description: "Download successful")
        Layer.downloadGeoPackage(layer: layer) {
            successfulDownload.fulfill()
        } failure: { error in
            XCTFail(error.localizedDescription)
        }
        
        await fulfillment(of: [geopackageStubCalled, successfulDownload], timeout: 3)
        
        let importedNotification = expectation(forNotification: .GeoPackageImported, object: nil)

        await GeoPackageImporter().importGeoPackageFileAsLink(urlPath.path, andMove: false, withLayerId: 1)

        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
        var geopackageImported = XCTestExpectation(description: "GeoPackage imported")
        
        await fulfillment(of: [importedNotification], timeout: 2)
        await CacheOverlays.getInstance().notifyListeners()
        geopackageImported.fulfill()
        
        await fulfillment(of: [geopackageImported], timeout: 2)
        
        var overlayCount = await CacheOverlays.getInstance().getOverlays().count
        XCTAssertEqual(overlayCount, 3)
        let count = await CacheOverlays.getInstance().getOverlays().count
        expect(count).to(equal(3))

        for overlay in await CacheOverlays.getInstance().getOverlays() {
            if overlay.cacheName == "gpkgWithMedia_1_from_server" {
                overlay.enabled = true
                for overlay in overlay.getChildren() {
                    overlay.enabled = true
                }
                UserDefaults.standard.selectedCaches = ["gpkgWithMedia_1_from_server"]
                await CacheOverlays.getInstance().notifyListeners()
            }
        }
        
        let predicate = NSPredicate { _, _ in
            if let overlays = self.testimpl.mapView?.overlays {
                return overlays.count == 1
            }
            return false
        }
        let countExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [countExpectation], timeout: 4)
        expect(self.testimpl.mapView?.overlays.count).to(equal(1))
        if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:39.57367, longitude:-104.66225), latitudinalMeters: 5000, longitudinalMeters: 5000)) {
            testimpl.mapView?.setRegion(region, animated: false)
        }

        let items = await mixin.itemKeys(at: CLLocationCoordinate2D(latitude: 39.57367, longitude: -104.66225), mapView: testimpl.mapView!, touchPoint: .zero)
        expect(items.count).to(equal(1))
        let item = items[DataSources.geoPackage.key]![0]
        let key = GeoPackageFeatureKey.fromKey(jsonString: item)
        XCTAssertEqual(key?.tableName, "Observations")
        XCTAssertEqual(key?.layerName, "Observations")
        XCTAssertEqual(key?.geoPackageName, "gpkgWithMedia_1_from_server")
        XCTAssertEqual(key?.featureCount, 1)
        XCTAssertEqual(key?.maxFeaturesFound, false)

        for overlay in await CacheOverlays.getInstance().getOverlays() {
            if overlay.cacheName == "gpkgWithMedia_1_from_server" {
                overlay.enabled = false
                for overlay in overlay.getChildren() {
                    overlay.enabled = false
                }
                UserDefaults.standard.selectedCaches = []
                await CacheOverlays.getInstance().notifyListeners()
            }
        }
        
        let predicate2 = NSPredicate { _, _ in
            if let overlays = self.testimpl.mapView?.overlays {
                return overlays.count == 0
            }
            return false
        }
        let countExpectation2 = XCTNSPredicateExpectation(predicate: predicate2, object: .none)
        await fulfillment(of: [countExpectation2], timeout: 4)

        expect(self.testimpl.mapView?.overlays.count).to(equal(0))
        
        mixin.cleanupMixin()
    }
}
