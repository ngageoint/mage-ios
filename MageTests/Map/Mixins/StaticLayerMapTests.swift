//
//  StaticLayerMapTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/14/22.
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

class StaticLayerMapTestImpl : NSObject, StaticLayerMap {
    var mapView: MKMapView?
    var scheme: AppContainerScheming?

    var staticLayerMapMixin: StaticLayerMapMixin?
}

extension StaticLayerMapTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return staticLayerMapMixin?.renderer(overlay: overlay) ?? staticLayerMapMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return staticLayerMapMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class StaticLayerMapTests: AsyncMageCoreDataTestCase {
    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    var testimpl: StaticLayerMapTestImpl!
    var mixin: StaticLayerMapMixin!
    
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
        
        testimpl = StaticLayerMapTestImpl()
        testimpl.mapView = mapView
        testimpl.scheme = MAGEScheme.scheme()
        mapView.delegate = testimpl
        
        navController = UINavigationController(rootViewController: controller);
        
        mixin = StaticLayerMapMixin(staticLayerMap: testimpl)
        testimpl.staticLayerMapMixin = mixin
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
    
    @MainActor
    func testInitializeTheStaticLayerMapWithANotLoadedLayerThenLoadItButDontAddToTheMap() async {
        var stubCalled = XCTestExpectation(description: "Layers Stub Called");
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers")
        ) { (request) -> HTTPStubsResponse in
            stubCalled.fulfill()
            return HTTPStubsResponse(jsonObject: [[
                LayerKey.id.key: 1,
                LayerKey.name.key: "name",
                LayerKey.description.key: "description",
                LayerKey.type.key: "Feature",
                LayerKey.url.key: "https://magetest/api/events/1/layers",
                LayerKey.state.key: "available"
            ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var featuresStubCalled = XCTestExpectation(description: "Features Stub Called");
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers/1/features")
        ) { (request) -> HTTPStubsResponse in
            featuresStubCalled.fulfill()
            let stubPath = OHPathForFile("staticFeatures.geojson", StaticLayerMapTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var iconStubCalled = XCTestExpectation(description: "Icon Stub Called");
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/testkmlicon.png")
        ) { (request) -> HTTPStubsResponse in
            iconStubCalled.fulfill()
            let stubPath = OHPathForFile("icon27.png", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        if (FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")) {
            do {
                try FileManager.default.removeItem(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")
            } catch {}
        }
        
        await awaitDidSave {
            Layer.refreshLayers(eventId: 1);
        }
        
        await fulfillment(of: [stubCalled], timeout: 2)
        
        context.performAndWait {
            let layers = try? self.context.fetchObjects(Layer.self)
            expect(layers?.count).to(equal(1))
            
            let layer = try! context.fetchFirst(Layer.self)!;
            expect(layer.remoteId).to(equal(1))
            expect(layer.name).to(equal("name"))
            expect(layer.type).to(equal("Feature"))
            expect(layer.eventId).to(equal(1))
            expect(layer.file).to(beNil());
            expect(layer.layerDescription).to(equal("description"))
            expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
            expect(layer.state).to(equal("available"))
            
            let sl = context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
            expect(sl).toNot(beNil())
            
            StaticLayer.fetchStaticLayerData(eventId: 1, staticLayer: sl!)
        }
            
        await fulfillment(of: [featuresStubCalled], timeout: 2)

        let predicate = NSPredicate { _, _ in
            let staticLayer = self.context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
            return staticLayer?.data != nil
        }
        let layerDataExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [layerDataExpectation], timeout: 2)
        
        let staticLayer = context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
        expect(staticLayer).toNot(beNil())
        
        expect(staticLayer!.data).toNot(beNil());
        expect(staticLayer!.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
        await fulfillment(of: [iconStubCalled], timeout: 2)

        let staticLayerFeatures = staticLayer!.data![LayerKey.features.key] as! [[AnyHashable : Any]];
        expect(staticLayerFeatures.count).to(equal(6));
        let lastFeature = staticLayerFeatures[2];
        let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
        expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
        
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
        
        context.performAndWait {
            let layer = try? context.fetchFirst(Layer.self)!;
            layer?.loaded = true
            try? context.save()
        }
        
        expect(self.testimpl.mapView?.overlays.count).to(equal(0))
        
        mixin.cleanupMixin()
    }
    
    @MainActor
    func testInitializeTheStaticLayerMapWithANotLoadedLayerThenLoadItAndAddToMap() async {
        var stubCalled = XCTestExpectation(description: "Layers Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers")
        ) { (request) -> HTTPStubsResponse in
            stubCalled.fulfill()
            return HTTPStubsResponse(jsonObject: [[
                LayerKey.id.key: 1,
                LayerKey.name.key: "name",
                LayerKey.description.key: "description",
                LayerKey.type.key: "Feature",
                LayerKey.url.key: "https://magetest/api/events/1/layers",
                LayerKey.state.key: "available"
            ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var featuresStubCalled = XCTestExpectation(description: "Features Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers/1/features")
        ) { (request) -> HTTPStubsResponse in
            featuresStubCalled.fulfill()
            let stubPath = OHPathForFile("staticFeatures.geojson", StaticLayerMapTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var iconStubCalled = XCTestExpectation(description: "Icon Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/testkmlicon.png")
        ) { (request) -> HTTPStubsResponse in
            iconStubCalled.fulfill()
            let stubPath = OHPathForFile("icon27.png", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        if (FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")) {
            do {
                try FileManager.default.removeItem(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")
            } catch {}
        }
        
        await awaitDidSave {
            Layer.refreshLayers(eventId: 1);
        }
        
        await fulfillment(of: [stubCalled], timeout: 2)
        let layers = try? self.context.fetchObjects(Layer.self)
        expect(layers?.count).to(equal(1))
        
        let layer = try! context.fetchFirst(Layer.self)!
        expect(layer.remoteId).to(equal(1))
        expect(layer.name).to(equal("name"))
        expect(layer.type).to(equal("Feature"))
        expect(layer.eventId).to(equal(1))
        expect(layer.file).to(beNil());
        expect(layer.layerDescription).to(equal("description"))
        expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
        expect(layer.state).to(equal("available"))
        
        let sl = context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
        expect(sl).toNot(beNil())
        
        StaticLayer.fetchStaticLayerData(eventId: 1, staticLayer: sl!)
        
        await fulfillment(of: [featuresStubCalled], timeout: 2)
        
        let predicate = NSPredicate { _, _ in
            let staticLayer = self.context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
            return staticLayer?.data != nil
        }
        let layerDataExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [layerDataExpectation], timeout: 2)
        
        let staticLayer = context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
        expect(staticLayer).toNot(beNil())
        
        expect(staticLayer!.data).toNot(beNil());
        expect(staticLayer!.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
        await fulfillment(of: [iconStubCalled], timeout: 2)
        
        let staticLayerFeatures = staticLayer!.data![LayerKey.features.key] as! [[AnyHashable : Any]];
        expect(staticLayerFeatures.count).to(equal(6));
        let lastFeature = staticLayerFeatures[2];
        let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
        expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
        
        context.performAndWait {
            let layer = try? context.fetchFirst(Layer.self)!;
            layer?.loaded = true
            try? context.save()
        }
        
        UserDefaults.standard.selectedStaticLayers = ["1": [1]]
        
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

        if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:39.7, longitude:-104.75), latitudinalMeters: 5000, longitudinalMeters: 5000)) {
            testimpl.mapView?.setRegion(region, animated: false)
        }
        
        expect(self.testimpl.mapView?.overlays.count).to(equal(4))
        expect(self.testimpl.mapView?.annotations.count).to(equal(2))
        
        var items = await mixin.itemKeys(at: CLLocationCoordinate2D(latitude: 39.7, longitude: -104.75), mapView: testimpl.mapView!, touchPoint: .zero)
        expect(items.count).to(equal(1))
        var item = items[DataSources.featureItem.key]![0]
        var key = FeatureItem.fromKey(jsonString: item)
        XCTAssertEqual(key?.featureTitle, "Runway1")
        XCTAssertEqual(key?.featureId, 0)
        XCTAssertEqual(key?.layerName, "name")

        items = await mixin.itemKeys(at: CLLocationCoordinate2D(latitude: 39.707, longitude: -104.761), mapView: testimpl.mapView!, touchPoint: .zero)
        expect(items.count).to(equal(1))
        item = items[DataSources.featureItem.key]![0]
        key = FeatureItem.fromKey(jsonString: item)
        XCTAssertEqual(key?.featureTitle, "Polygon with a hole")
        XCTAssertEqual(key?.featureId, 0)
        XCTAssertEqual(key?.layerName, "name")
                        
        mixin.cleanupMixin()
    }

    @MainActor
    func testInitializeTheStaticLayerMapWithANotLoadedLayerThenLoadItAndChangeTheUserDefaultsToAddItToTheMap() async {
        var stubCalled = XCTestExpectation(description: "Layers Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers")
        ) { (request) -> HTTPStubsResponse in
            stubCalled.fulfill()
            return HTTPStubsResponse(jsonObject: [[
                LayerKey.id.key: 1,
                LayerKey.name.key: "name",
                LayerKey.description.key: "description",
                LayerKey.type.key: "Feature",
                LayerKey.url.key: "https://magetest/api/events/1/layers",
                LayerKey.state.key: "available"
            ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var featuresStubCalled = XCTestExpectation(description: "Features Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers/1/features")
        ) { (request) -> HTTPStubsResponse in
            featuresStubCalled.fulfill()
            let stubPath = OHPathForFile("staticFeatures.geojson", StaticLayerMapTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var iconStubCalled = XCTestExpectation(description: "Icon Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/testkmlicon.png")
        ) { (request) -> HTTPStubsResponse in
            iconStubCalled.fulfill()
            let stubPath = OHPathForFile("icon27.png", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        if (FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")) {
            do {
                try FileManager.default.removeItem(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")
            } catch {}
        }
        
        await awaitDidSave {
            Layer.refreshLayers(eventId: 1);
        }
        
        await fulfillment(of: [stubCalled], timeout: 2)
        let layers = try? self.context.fetchObjects(Layer.self)
        expect(layers?.count).to(equal(1))
        
        let layer = try! context.fetchFirst(Layer.self)!
        expect(layer.remoteId).to(equal(1))
        expect(layer.name).to(equal("name"))
        expect(layer.type).to(equal("Feature"))
        expect(layer.eventId).to(equal(1))
        expect(layer.file).to(beNil());
        expect(layer.layerDescription).to(equal("description"))
        expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
        expect(layer.state).to(equal("available"))
        
        let sl = context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
        expect(sl).toNot(beNil())
        
        StaticLayer.fetchStaticLayerData(eventId: 1, staticLayer: sl!)
        
        await fulfillment(of: [featuresStubCalled], timeout: 2)
        
        let predicate = NSPredicate { _, _ in
            let staticLayer = self.context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
            return staticLayer?.data != nil
        }
        let layerDataExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [layerDataExpectation], timeout: 2)
        
        let staticLayer = context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
        expect(staticLayer).toNot(beNil())
        
        expect(staticLayer!.data).toNot(beNil());
        expect(staticLayer!.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
        await fulfillment(of: [iconStubCalled], timeout: 2)
        
        let staticLayerFeatures = staticLayer!.data![LayerKey.features.key] as! [[AnyHashable : Any]];
        expect(staticLayerFeatures.count).to(equal(6));
        let lastFeature = staticLayerFeatures[2];
        let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
        expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
        
        context.performAndWait {
            let layer = try? context.fetchFirst(Layer.self)!;
            layer?.loaded = true
            try? context.save()
        }
        
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

        if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:39.7, longitude:-104.75), latitudinalMeters: 5000, longitudinalMeters: 5000)) {
            testimpl.mapView?.setRegion(region, animated: false)
        }
        
        expect(self.testimpl.mapView?.overlays.count).to(equal(0))
        expect(self.testimpl.mapView?.annotations.count).to(equal(0))
                        
        UserDefaults.standard.selectedStaticLayers = ["1": [1]]
        
        var annoatationsPredicate = NSPredicate { _, _ in
          // some logic returning true if the expectation is met
            if let overlays = self.testimpl.mapView?.overlays, let annotations = self.testimpl.mapView?.annotations {
                return overlays.count == 4 && annotations.count == 2
            }
            return false
        }
        let countExpectation = XCTNSPredicateExpectation(predicate: annoatationsPredicate, object: .none)
        
        await fulfillment(of: [countExpectation], timeout: 2)
        
        expect(self.testimpl.mapView?.overlays.count).to(equal(4))
        expect(self.testimpl.mapView?.annotations.count).to(equal(2))
                        
        UserDefaults.standard.selectedStaticLayers = ["1": []]
        
        var annoatationsPredicate2 = NSPredicate { _, _ in
          // some logic returning true if the expectation is met
            if let overlays = self.testimpl.mapView?.overlays, let annotations = self.testimpl.mapView?.annotations {
                return overlays.count == 0 && annotations.count == 0
            }
            return false
        }
        let countExpectation2 = XCTNSPredicateExpectation(predicate: annoatationsPredicate2, object: .none)
        await fulfillment(of: [countExpectation2], timeout: 2)
        
        expect(self.testimpl.mapView?.overlays.count).to(equal(0))
        expect(self.testimpl.mapView?.annotations.count).to(equal(0))
                        
        mixin.cleanupMixin()
    }
    
    @MainActor
    func testFocusOnAnAnnotationThenClearTheFocus() async {
        var stubCalled = XCTestExpectation(description: "Layers Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers")
        ) { (request) -> HTTPStubsResponse in
            stubCalled.fulfill()
            return HTTPStubsResponse(jsonObject: [[
                LayerKey.id.key: 1,
                LayerKey.name.key: "name",
                LayerKey.description.key: "description",
                LayerKey.type.key: "Feature",
                LayerKey.url.key: "https://magetest/api/events/1/layers",
                LayerKey.state.key: "available"
            ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var featuresStubCalled = XCTestExpectation(description: "Features Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers/1/features")
        ) { (request) -> HTTPStubsResponse in
            featuresStubCalled.fulfill()
            let stubPath = OHPathForFile("staticFeatures.geojson", StaticLayerMapTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var iconStubCalled = XCTestExpectation(description: "Icon Stub Called")
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/testkmlicon.png")
        ) { (request) -> HTTPStubsResponse in
            iconStubCalled.fulfill()
            let stubPath = OHPathForFile("icon27.png", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        if (FileManager.default.isDeletableFile(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")) {
            do {
                try FileManager.default.removeItem(atPath: "\(documentsDirectory)/featureIcons/1/5cb352704bd2b9500b967765")
            } catch {}
        }
        
        await awaitDidSave {
            Layer.refreshLayers(eventId: 1);
        }
        
        await fulfillment(of: [stubCalled], timeout: 2)
        let layers = try? self.context.fetchObjects(Layer.self)
        expect(layers?.count).to(equal(1))
        
        let layer = try! context.fetchFirst(Layer.self)!
        expect(layer.remoteId).to(equal(1))
        expect(layer.name).to(equal("name"))
        expect(layer.type).to(equal("Feature"))
        expect(layer.eventId).to(equal(1))
        expect(layer.file).to(beNil());
        expect(layer.layerDescription).to(equal("description"))
        expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
        expect(layer.state).to(equal("available"))
        
        let sl = context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
        expect(sl).toNot(beNil())
        
        StaticLayer.fetchStaticLayerData(eventId: 1, staticLayer: sl!)
        
        await fulfillment(of: [featuresStubCalled], timeout: 2)
        
        let predicate = NSPredicate { _, _ in
            let staticLayer = self.context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
            return staticLayer?.data != nil
        }
        let layerDataExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [layerDataExpectation], timeout: 2)
        
        let staticLayer = context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
        expect(staticLayer).toNot(beNil())
        expect(staticLayer!.data).toNot(beNil());
        expect(staticLayer!.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
        await fulfillment(of: [iconStubCalled], timeout: 2)
        
        let staticLayerFeatures = staticLayer!.data![LayerKey.features.key] as! [[AnyHashable : Any]];
        expect(staticLayerFeatures.count).to(equal(6));
        let lastFeature = staticLayerFeatures[2];
        let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
        expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
        
        context.performAndWait {
            let layer = try? context.fetchFirst(Layer.self)!;
            layer?.loaded = true
            try? context.save()
        }
        
        UserDefaults.standard.selectedStaticLayers = ["1": [1]]

        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
        
        if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:39.7, longitude:-104.75), latitudinalMeters: 5000, longitudinalMeters: 5000)) {
            testimpl.mapView?.setRegion(region, animated: false)
        }
        
        var annotationsPredicate = NSPredicate { _, _ in
          // some logic returning true if the expectation is met
            if let overlays = self.testimpl.mapView?.overlays, let annotations = self.testimpl.mapView?.annotations {
                return overlays.count == 4 && annotations.count == 2
            }
            return false
        }
        let countExpectation = XCTNSPredicateExpectation(predicate: annotationsPredicate, object: .none)

        await fulfillment(of: [countExpectation], timeout: 2)
        expect(self.testimpl.mapView?.overlays.count).to(equal(4))
        expect(self.testimpl.mapView?.annotations.count).to(equal(2))
        
        var initialLocation: CLLocationCoordinate2D?
        var originalHeight = 0.0
        var la: StaticPointAnnotation?
        for annotation in testimpl.mapView!.annotations {
            la = annotation as? StaticPointAnnotation
            guard let la = la else {
                tester().fail()
                return
            }
            
            if la.title != "Point" {
                continue
            }
            
            initialLocation = la.coordinate
            
            guard let initialLocation = initialLocation else {
                tester().fail()
                return
            }
            
            if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: initialLocation, latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                testimpl.mapView?.setRegion(region, animated: false)
            }
            
            let centerPredicate = NSPredicate { _, _ in
                guard let centerCoordinate = self.testimpl.mapView?.centerCoordinate else { return false }
                return centerCoordinate.latitude - 0.1 <= initialLocation.latitude
                && centerCoordinate.latitude + 0.1 >= initialLocation.latitude
                && centerCoordinate.longitude - 0.1 <= initialLocation.longitude
                && centerCoordinate.longitude + 0.1 >= initialLocation.longitude
            }
            let centerExpecation = XCTNSPredicateExpectation(predicate: centerPredicate, object: .none)
            await fulfillment(of: [centerExpecation], timeout: 2)
            
            expect(la.view).to(beAKindOf(MKAnnotationView.self))
            if let lav = la.view {
                originalHeight = lav.frame.size.height
                expect(lav.isEnabled).to(beFalse())
                expect(lav.canShowCallout).to(beFalse())
                expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))
                
                let notification = MapAnnotationFocusedNotification(annotation: la, mapView: testimpl.mapView)
                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                let heightPredicate = NSPredicate { _, _ in
                    guard let centerCoordinate = self.testimpl.mapView?.centerCoordinate else { return false }
                    return lav.frame.size.height == originalHeight * 2.0
                }
                let heightExpecation = XCTNSPredicateExpectation(predicate: heightPredicate, object: .none)
                await fulfillment(of: [heightExpecation], timeout: 2)
                expect(self.mixin.enlargedAnnotationView).to(equal(lav))
                
                // post again, ensure it doesn't double in size again
                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                expect(self.mixin.enlargedAnnotationView).to(equal(lav))
                let heightPredicate2 = NSPredicate { _, _ in
                    guard let centerCoordinate = self.testimpl.mapView?.centerCoordinate else { return false }
                    return lav.frame.size.height == originalHeight * 2.0
                }
                let heightExpecation2 = XCTNSPredicateExpectation(predicate: heightPredicate2, object: .none)
                await fulfillment(of: [heightExpecation2], timeout: 2)
            }
        }

        // focus on a different one
        var la2: StaticPointAnnotation?
        for annotation in testimpl.mapView!.annotations {
            la2 = annotation as? StaticPointAnnotation
            guard let la2 = la2 else {
                tester().fail()
                return
            }
            if la2.title != "Point2" {
                continue
            }
            
            initialLocation = la2.coordinate
            
            guard let initialLocation = initialLocation else {
                tester().fail()
                return
            }
            
            if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: initialLocation, latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                testimpl.mapView?.setRegion(region, animated: false)
            }
            
            let centerPredicate2 = NSPredicate { _, _ in
                guard let centerCoordinate = self.testimpl.mapView?.centerCoordinate else { return false }
                return centerCoordinate.latitude - 0.1 <= initialLocation.latitude
                && centerCoordinate.latitude + 0.1 >= initialLocation.latitude
                && centerCoordinate.longitude - 0.1 <= initialLocation.longitude
                && centerCoordinate.longitude + 0.1 >= initialLocation.longitude
            }
            let centerExpecation2 = XCTNSPredicateExpectation(predicate: centerPredicate2, object: .none)
            await fulfillment(of: [centerExpecation2], timeout: 2)
            
            expect(la2.view).to(beAKindOf(MKAnnotationView.self))
            if let lav = la2.view {
                originalHeight = lav.frame.size.height
                expect(lav.isEnabled).to(beFalse())
                expect(lav.canShowCallout).to(beFalse())
                expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))
                
                let notification2 = MapAnnotationFocusedNotification(annotation: la2, mapView: testimpl.mapView)
                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification2)
                let heightPredicate3 = NSPredicate { _, _ in
                    return lav.frame.size.height == originalHeight * 2.0
                }
                let heightExpecation3 = XCTNSPredicateExpectation(predicate: heightPredicate3, object: .none)
                await fulfillment(of: [heightExpecation3], timeout: 2)
                expect(self.mixin.enlargedAnnotationView).to(equal(lav))
            }
        }
        
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        let enlargedNilPredicate = NSPredicate { _, _ in
            return self.mixin.enlargedAnnotationView == nil
        }
        let enlargedNilExpecation = XCTNSPredicateExpectation(predicate: enlargedNilPredicate, object: .none)
        await fulfillment(of: [enlargedNilExpecation], timeout: 2)
        
        for annotation in testimpl.mapView!.annotations {
            if let la = annotation as? StaticPointAnnotation {
                expect(la.view).to(beAKindOf(MKAnnotationView.self))
                if let lav = la.view {
                    let heightPredicate4 = NSPredicate { _, _ in
                        return lav.frame.size.height == originalHeight
                    }
                    let heightExpecation4 = XCTNSPredicateExpectation(predicate: heightPredicate4, object: .none)
                    await fulfillment(of: [heightExpecation4], timeout: 2)
                }
            }
        }
        
        mixin.cleanupMixin()
    }
}
