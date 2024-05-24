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

class GeoPackageLayerMapTests: KIFSpec {
    
    override func spec() {
        
        describe("GeoPackageLayerMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: GeoPackageLayerMapTestImpl!
            var mixin: GeoPackageLayerMapMixin!
            
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
                
                var geopackageStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/1")
                ) { (request) -> HTTPStubsResponse in
                    geopackageStubCalled = true;
                    let stubPath = OHPathForFile("gpkgWithMedia.gpkg", ObservationTests.self);
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
                
                Layer.refreshLayers(eventId: 1);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
                let layer = Layer.mr_findFirst()!;
                expect(layer.remoteId).to(equal(1))
                expect(layer.name).to(equal("name"))
                expect(layer.type).to(equal("GeoPackage"))
                expect(layer.eventId).to(equal(1))
                expect(layer.file).toNot(beNil());
                expect(layer.layerDescription).to(equal("description"))
                expect(layer.state).to(equal("available"))
                
                var successfulDownload = false
                Layer.downloadGeoPackage(layer: layer) {
                    print("Successful download")
                    successfulDownload = true
                } failure: { error in
                    tester().failWithError(error, stopTest: false)
                }

                expect(geopackageStubCalled).toEventually(beTrue());
                expect(successfulDownload).toEventually(beTrue())
                
                GeoPackageImporter().importGeoPackageFile(asLink: urlPath.path, andMove: false, withLayerId: "1")

                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                var geopackageImported = false
                
                NotificationCenter.default.addObserver(forName: .GeoPackageImported, object: nil, queue: .main) {  notification in
                    CacheOverlays.getInstance().notifyListeners()
                    geopackageImported = true
                }
                
                expect(geopackageImported).toEventually(beTrue())
                
                expect(CacheOverlays.getInstance().getOverlays()!.count).toEventually(equal(3))
                for overlay in CacheOverlays.getInstance().getOverlays() {
                    if overlay.getCacheName() == "gpkgWithMedia_1_from_server" {
                        overlay.enabled = true
                        for overlay in overlay.getChildren() {
                            overlay.enabled = true
                        }
                        UserDefaults.standard.selectedCaches = ["gpkgWithMedia_1_from_server"]
                        CacheOverlays.getInstance().notifyListeners()
                    }
                }
                
                expect(testimpl.mapView?.overlays.count).toEventually(equal(1))
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:39.57367, longitude:-104.66225), latitudinalMeters: 5000, longitudinalMeters: 5000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }
                
                tester().wait(forTimeInterval: 6)

                // TODO: redo for async
//                let items = mixin.items(at: CLLocationCoordinate2D(latitude: 39.57367, longitude: -104.66225), mapView: testimpl.mapView!, touchPoint: .zero)
//                expect(items?.count).to(equal(1))
//                let item = items![0] as! GeoPackageFeatureItem
//                expect(item.layerName).to(equal("Observations"))
//                expect(item.featureId).to(equal(1))
                
                for overlay in CacheOverlays.getInstance().getOverlays() {
                    if overlay.getCacheName() == "gpkgWithMedia_1_from_server" {
                        overlay.enabled = false
                        for overlay in overlay.getChildren() {
                            overlay.enabled = false
                        }
                        UserDefaults.standard.selectedCaches = []
                        CacheOverlays.getInstance().notifyListeners()
                    }
                }
                
                expect(testimpl.mapView?.overlays.count).toEventually(equal(0))
                
                mixin.cleanupMixin()
            }
        }
    }
}
