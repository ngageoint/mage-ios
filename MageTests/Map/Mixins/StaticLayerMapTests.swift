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

@testable import MAGE
import CoreLocation
import MapKit

class StaticLayerMapTestImpl : NSObject, StaticLayerMap {
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?

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

class StaticLayerMapTests: KIFSpec {
    
    override func spec() {
        
        describe("StaticLayerMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: StaticLayerMapTestImpl!
            var mixin: StaticLayerMapMixin!
            
            beforeEach {
                
                if (navController != nil) {
                    waitUntil { done in
                        navController.dismiss(animated: false, completion: {
                            done();
                        });
                    }
                }
                TestHelpers.clearAndSetUpStack();
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
            
            afterEach {
                mixin = nil
                testimpl = nil
                
                for subview in view.subviews {
                    subview.removeFromSuperview();
                }
                waitUntil { done in
                    controller.dismiss(animated: false, completion: {
                        done();
                    });
                }
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
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs()
            }
            
            it("initialize the StaticLayerMap with a not loaded layer then load it but don't add to the map") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.description.key: "description",
                        LayerKey.type.key: "Feature",
                        LayerKey.url.key: "https://magetest/api/events/1/layers",
                        LayerKey.state.key: "available"
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var featuresStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1/features")
                ) { (request) -> HTTPStubsResponse in
                    featuresStubCalled = true;
                    let stubPath = OHPathForFile("staticFeatures.geojson", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var iconStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/testkmlicon.png")
                ) { (request) -> HTTPStubsResponse in
                    iconStubCalled = true;
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
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("Feature"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).to(beNil());
                expect(layer.layerDescription).to(equal("description"))
                expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
                expect(layer.state).to(equal("available"))
                
                expect(featuresStubCalled).toEventually(beTrue());
                
                expect(StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.data).toEventuallyNot(beNil(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
                
                let staticLayer = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())!
                expect(staticLayer.data).toNot(beNil());
                expect(staticLayer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
                expect(iconStubCalled).toEventually(beTrue());
                
                let staticLayerFeatures = staticLayer.data![LayerKey.features.key] as! [[AnyHashable : Any]];
                expect(staticLayerFeatures.count).to(equal(6));
                let lastFeature = staticLayerFeatures[2];
                let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
                expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
                
                mixin.setupMixin()
                                
                MagicalRecord.save(blockAndWait:{ (localContext: NSManagedObjectContext) in
                    let layer = Layer.mr_findFirst()
                    expect(layer).toNot(beNil())
                    layer?.loaded = true
                })
                
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the StaticLayerMap with a not loaded layer then load it and add to map") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.description.key: "description",
                        LayerKey.type.key: "Feature",
                        LayerKey.url.key: "https://magetest/api/events/1/layers",
                        LayerKey.state.key: "available"
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var featuresStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1/features")
                ) { (request) -> HTTPStubsResponse in
                    featuresStubCalled = true;
                    let stubPath = OHPathForFile("staticFeatures.geojson", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var iconStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/testkmlicon.png")
                ) { (request) -> HTTPStubsResponse in
                    iconStubCalled = true;
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
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("Feature"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).to(beNil());
                expect(layer.layerDescription).to(equal("description"))
                expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
                expect(layer.state).to(equal("available"))
                
                expect(featuresStubCalled).toEventually(beTrue());
                
                expect(StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.data).toEventuallyNot(beNil(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
                
                let staticLayer = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())!
                expect(staticLayer.data).toNot(beNil());
                expect(staticLayer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
                expect(iconStubCalled).toEventually(beTrue());
                
                let staticLayerFeatures = staticLayer.data![LayerKey.features.key] as! [[AnyHashable : Any]];
                expect(staticLayerFeatures.count).to(equal(6));
                let lastFeature = staticLayerFeatures[2];
                let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
                expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
                
                MagicalRecord.save(blockAndWait:{ (localContext: NSManagedObjectContext) in
                    let layer = Layer.mr_findFirst()
                    expect(layer).toNot(beNil())
                    layer?.loaded = true
                })
                
                UserDefaults.standard.selectedStaticLayers = ["1": [1]]
                
                mixin.setupMixin()
                
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:39.7, longitude:-104.75), latitudinalMeters: 5000, longitudinalMeters: 5000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }
                
                expect(testimpl.mapView?.overlays.count).to(equal(4))
                expect(testimpl.mapView?.annotations.count).to(equal(2))
                
                var items = mixin.items(at: CLLocationCoordinate2D(latitude: 39.7, longitude: -104.75))
                expect(items?.count).to(equal(1))
                var item = items![0] as! FeatureItem
                expect(item.featureTitle).to(equal("Runway1"))
                
                items = mixin.items(at: CLLocationCoordinate2D(latitude: 39.707, longitude: -104.761))
                expect(items?.count).to(equal(1))
                item = items![0] as! FeatureItem
                expect(item.featureTitle).to(equal("Polygon with a hole"))
                                
                mixin.cleanupMixin()
            }
        
            it("initialize the StaticLayerMap with a not loaded layer then load it and change the user defaults to add it to the map") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.description.key: "description",
                        LayerKey.type.key: "Feature",
                        LayerKey.url.key: "https://magetest/api/events/1/layers",
                        LayerKey.state.key: "available"
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var featuresStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1/features")
                ) { (request) -> HTTPStubsResponse in
                    featuresStubCalled = true;
                    let stubPath = OHPathForFile("staticFeatures.geojson", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var iconStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/testkmlicon.png")
                ) { (request) -> HTTPStubsResponse in
                    iconStubCalled = true;
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
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("Feature"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).to(beNil());
                expect(layer.layerDescription).to(equal("description"))
                expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
                expect(layer.state).to(equal("available"))
                
                expect(featuresStubCalled).toEventually(beTrue());
                
                expect(StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.data).toEventuallyNot(beNil(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
                
                let staticLayer = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())!
                expect(staticLayer.data).toNot(beNil());
                expect(staticLayer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
                expect(iconStubCalled).toEventually(beTrue());
                
                let staticLayerFeatures = staticLayer.data![LayerKey.features.key] as! [[AnyHashable : Any]];
                expect(staticLayerFeatures.count).to(equal(6));
                let lastFeature = staticLayerFeatures[2];
                let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
                expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
                
                MagicalRecord.save(blockAndWait:{ (localContext: NSManagedObjectContext) in
                    let layer = Layer.mr_findFirst()
                    expect(layer).toNot(beNil())
                    layer?.loaded = true
                })
                
                mixin.setupMixin()
                
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:39.7, longitude:-104.75), latitudinalMeters: 5000, longitudinalMeters: 5000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }
                
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                                
                UserDefaults.standard.selectedStaticLayers = ["1": [1]]
                
                expect(testimpl.mapView?.overlays.count).toEventually(equal(4))
                expect(testimpl.mapView?.annotations.count).toEventually(equal(2))
                                
                UserDefaults.standard.selectedStaticLayers = ["1": []]
                
                expect(testimpl.mapView?.overlays.count).toEventually(equal(0))
                expect(testimpl.mapView?.annotations.count).toEventually(equal(0))
                                
                mixin.cleanupMixin()
            }
            
            it("focus on an annotation then clear the focus") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers")
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: [[
                        LayerKey.id.key: 1,
                        LayerKey.name.key: "name",
                        LayerKey.description.key: "description",
                        LayerKey.type.key: "Feature",
                        LayerKey.url.key: "https://magetest/api/events/1/layers",
                        LayerKey.state.key: "available"
                    ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var featuresStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1/features")
                ) { (request) -> HTTPStubsResponse in
                    featuresStubCalled = true;
                    let stubPath = OHPathForFile("staticFeatures.geojson", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var iconStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/testkmlicon.png")
                ) { (request) -> HTTPStubsResponse in
                    iconStubCalled = true;
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
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("Feature"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).to(beNil());
                expect(layer.layerDescription).to(equal("description"))
                expect(layer.url).to(equal("https://magetest/api/events/1/layers"))
                expect(layer.state).to(equal("available"))
                
                expect(featuresStubCalled).toEventually(beTrue());
                
                expect(StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())?.data).toEventuallyNot(beNil(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer")
                
                let staticLayer = StaticLayer.mr_findFirst(byAttribute: "eventId", withValue: 1, in: NSManagedObjectContext.mr_default())!
                expect(staticLayer.data).toNot(beNil());
                expect(staticLayer.loaded).to(equal(NSNumber(floatLiteral:Layer.OFFLINE_LAYER_LOADED)))
                expect(iconStubCalled).toEventually(beTrue());
                
                let staticLayerFeatures = staticLayer.data![LayerKey.features.key] as! [[AnyHashable : Any]];
                expect(staticLayerFeatures.count).to(equal(6));
                let lastFeature = staticLayerFeatures[2];
                let href = (((((lastFeature[StaticLayerKey.properties.key] as! [AnyHashable : Any])[StaticLayerKey.style.key] as! [AnyHashable : Any])[StaticLayerKey.iconStyle.key] as! [AnyHashable : Any])[StaticLayerKey.icon.key] as! [AnyHashable : Any])[StaticLayerKey.href.key] as! String)
                expect(href).to(equal("featureIcons/1/\(lastFeature[LayerKey.id.key] as! String)"))
                
                MagicalRecord.save(blockAndWait:{ (localContext: NSManagedObjectContext) in
                    let layer = Layer.mr_findFirst()
                    expect(layer).toNot(beNil())
                    layer?.loaded = true
                })
                
                UserDefaults.standard.selectedStaticLayers = ["1": [1]]

                mixin.setupMixin()
                
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:39.7, longitude:-104.75), latitudinalMeters: 5000, longitudinalMeters: 5000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }

                expect(testimpl.mapView?.overlays.count).toEventually(equal(4))
                expect(testimpl.mapView?.annotations.count).toEventually(equal(2))
                
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
                    
                    expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.1))
                    expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.1))
                    
                    expect(la.view).to(beAKindOf(MKAnnotationView.self))
                    if let lav = la.view {
                        originalHeight = lav.frame.size.height
                        expect(lav.isEnabled).to(beFalse())
                        expect(lav.canShowCallout).to(beFalse())
                        expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))
                        
                        let notification = MapAnnotationFocusedNotification(annotation: la, mapView: testimpl.mapView)
                        NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                        expect(lav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                        expect(mixin.enlargedAnnotationView).to(equal(lav))
                        
                        // post again, ensure it doesn't double in size again
                        NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                        expect(mixin.enlargedAnnotationView).to(equal(lav))
                        expect(lav.frame.size.height).toEventually(equal(originalHeight * 2.0))
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
                    
                    expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.1))
                    expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.1))
                    
                    expect(la2.view).to(beAKindOf(MKAnnotationView.self))
                    if let lav = la2.view {
                        originalHeight = lav.frame.size.height
                        expect(lav.isEnabled).to(beFalse())
                        expect(lav.canShowCallout).to(beFalse())
                        expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))
                        
                        let notification2 = MapAnnotationFocusedNotification(annotation: la2, mapView: testimpl.mapView)
                        NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification2)
                        expect(lav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                        expect(mixin.enlargedAnnotationView).to(equal(lav))
                    }
                }
                
                NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
                expect(mixin.enlargedAnnotationView).toEventually(beNil())
                
                for annotation in testimpl.mapView!.annotations {
                    if let la = annotation as? StaticPointAnnotation {
                        expect(la.view).to(beAKindOf(MKAnnotationView.self))
                        if let lav = la.view {
                            expect(lav.frame.size.height).toEventually(equal(originalHeight))
                        }
                    }
                }
                
                mixin.cleanupMixin()
            }
        }
    }
}
