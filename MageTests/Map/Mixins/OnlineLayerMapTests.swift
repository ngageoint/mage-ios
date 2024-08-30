//
//  OnlineLayerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/21/22.
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

class OnlineLayerMapTestImpl : NSObject {
    var scheme: MDCContainerScheming?
    var mapView: MKMapView?
    
    var onlineLayerMapMixin: OnlineLayerMapMixin?
}

extension OnlineLayerMapTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return onlineLayerMapMixin?.renderer(overlay: overlay) ?? onlineLayerMapMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return onlineLayerMapMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class OnlineLayerMapTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("OnlineLayerMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: OnlineLayerMapTestImpl!
            var mixin: OnlineLayerMapMixin!
            var userabc: User!
            
            var coreDataStack: TestCoreDataStack?
            var context: NSManagedObjectContext!
            
            beforeEach {
                
                if (navController != nil) {
                    waitUntil { done in
                        navController.dismiss(animated: false, completion: {
                            done();
                        });
                    }
                }
                coreDataStack = TestCoreDataStack()
                context = coreDataStack!.persistentContainer.newBackgroundContext()
                InjectedValues[\.nsManagedObjectContext] = context
//                TestHelpers.clearAndSetUpStack();
                if (view != nil) {
                    for subview in view.subviews {
                        subview.removeFromSuperview();
                    }
                }
                window = TestHelpers.getKeyWindowVisible();
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.selectedOnlineLayers = nil
                
                MageCoreDataFixtures.addEvent(context: context, remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                Server.setCurrentEventId(1);
                
                controller = UIViewController()
                let mapView = MKMapView()
                controller.view = mapView
                
                testimpl = OnlineLayerMapTestImpl()
                testimpl.mapView = mapView
                testimpl.scheme = MAGEScheme.scheme()
                mapView.delegate = testimpl
                
                mixin = OnlineLayerMapMixin()
                testimpl.onlineLayerMapMixin = mixin
                
                navController = UINavigationController(rootViewController: controller);
                
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
                UserDefaults.standard.selectedOnlineLayers = nil

                UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
                
                if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                    window.overrideUserInterfaceStyle = .unspecified
                }
                window?.resignKey();
                window.rootViewController = nil;
                navController = nil;
                view = nil;
                window = nil;
                InjectedValues[\.nsManagedObjectContext] = nil
                coreDataStack!.reset()
//                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs()
            }
            
            func getxyz(path: String) -> [Int] {
                var zoomLevel: Int?
                var xTile: Int?
                var yTile: Int?
                let regex: NSRegularExpression = try! NSRegularExpression(pattern: "/xyzlayer/(\\d+)/(\\d+)/(\\d+).png", options: [])
                regex.enumerateMatches(in: path,
                                       options: [],
                                       range: NSRange(location: 0, length: path.count)) { (match, _, stop) in
                    guard let match = match else { return }
                    
                    if match.numberOfRanges == 4,
                       let zRange = Range(match.range(at: 1), in: path),
                       let xRange = Range(match.range(at: 2), in: path),
                       let yRange = Range(match.range(at: 3), in: path),
                       let x = Int(path[xRange]),
                       let y = Int(path[yRange]),
                       let z = Int(path[zRange])
                    {
                        zoomLevel = z
                        xTile = x
                        yTile = y
                        stop.pointee = true
                    }
                }
                
                return [xTile!, yTile!, zoomLevel!]
            }
            
            it("initialize the OnlineLayerMap with xyz layer") {
                var tileStubCalledCount = 0
                let regex: NSRegularExpression = try! NSRegularExpression(pattern: "/xyzlayer/(\\d+)/(\\d+)/(\\d+).png", options: [])
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     pathMatches(regex)
                ) { (request) -> HTTPStubsResponse in
                    tileStubCalledCount += 1
                    let stubPath = OHPathForFile("tile.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                MageCoreDataFixtures.addImageryLayer(format: "TMS")
                
                UserDefaults.standard.selectedOnlineLayers = ["1": [1]]
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.overlays[0]).to(beAKindOf(TMSTileOverlay.self))
                // no real way to calculate this, so if phone sizes change this may change as well
                // but we want all of the stubs to finish before we end the test
                expect(tileStubCalledCount).toEventually(equal(32))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the OnlineLayerMap with tms layer") {
                var tileStubCalledCount = 0
                let regex: NSRegularExpression = try! NSRegularExpression(pattern: "/xyzlayer/(\\d+)/(\\d+)/(\\d+).png", options: [])
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     pathMatches(regex)
                ) { (request) -> HTTPStubsResponse in
                    tileStubCalledCount += 1
                    let stubPath = OHPathForFile("tile.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                MageCoreDataFixtures.addImageryLayer()
                
                UserDefaults.standard.selectedOnlineLayers = ["1": [1]]
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.overlays[0]).to(beAKindOf(XYZTileOverlay.self))
                // no real way to calculate this, so if phone sizes change this may change as well
                // but we want all of the stubs to finish before we end the test
                expect(tileStubCalledCount).toEventually(equal(32))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the OnlineLayerMap with wms layer") {
                
                let options: [String: Any] = [
                    WMSLayerOptionsKey.styles.key: "style",
                    WMSLayerOptionsKey.layers.key: "layer1,layer2",
                    WMSLayerOptionsKey.version.key: "1.3",
                    WMSLayerOptionsKey.format.key: "format",
                    WMSLayerOptionsKey.transparent.key: 1
                ]
                MageCoreDataFixtures.addImageryLayer(eventId: 1, layerId: 1, format: "WMS", url: "https://magetest/wmslayer", base: true, options: options, completion: nil)
                
                var tileStubCalledCount = 0
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/wmslayer") &&
                     containsQueryParams([
                        "request": "GetMap",
                        "service": "WMS",
                        "styles": options[WMSLayerOptionsKey.styles.key] as? String,
                        "layers": options[WMSLayerOptionsKey.layers.key] as? String,
                        "version": options[WMSLayerOptionsKey.version.key] as? String,
                        "width": "256",
                        "height": "256",
                        "format": "format",
                        "transparent": options[WMSLayerOptionsKey.transparent.key] as! Int == 1 ? "true" : "false"
                     ])
                ) { (request) -> HTTPStubsResponse in
                    tileStubCalledCount += 1
                    let stubPath = OHPathForFile("tile.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                UserDefaults.standard.selectedOnlineLayers = ["1": [1]]
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.overlays[0]).to(beAKindOf(WMSTileOverlay.self))
                // no real way to calculate this, so if phone sizes change this may change as well
                // but we want all of the stubs to finish before we end the test
                expect(tileStubCalledCount).toEventually(equal(32))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the OnlineLayerMap without layer added, then add it") {
                var tileStubCalledCount = 0
                let regex: NSRegularExpression = try! NSRegularExpression(pattern: "/xyzlayer/(\\d+)/(\\d+)/(\\d+).png", options: [])
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     pathMatches(regex)
                ) { (request) -> HTTPStubsResponse in
                    tileStubCalledCount += 1
                    let stubPath = OHPathForFile("tile.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                MageCoreDataFixtures.addImageryLayer()
                                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))

                UserDefaults.standard.selectedOnlineLayers = ["1": [1]]

                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.overlays[0]).to(beAKindOf(XYZTileOverlay.self))
                // no real way to calculate this, so if phone sizes change this may change as well
                // but we want all of the stubs to finish before we end the test
                expect(tileStubCalledCount).toEventually(equal(32))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the OnlineLayerMap without layer added, then add it, then remove it") {
                var tileStubCalledCount = 0
                let regex: NSRegularExpression = try! NSRegularExpression(pattern: "/xyzlayer/(\\d+)/(\\d+)/(\\d+).png", options: [])
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     pathMatches(regex)
                ) { (request) -> HTTPStubsResponse in
                    tileStubCalledCount += 1
                    let stubPath = OHPathForFile("tile.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                MageCoreDataFixtures.addImageryLayer()
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))

                UserDefaults.standard.selectedOnlineLayers = ["1": [1]]
                
                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.overlays[0]).to(beAKindOf(XYZTileOverlay.self))
                // no real way to calculate this, so if phone sizes change this may change as well
                // but we want all of the stubs to finish before we end the test
                expect(tileStubCalledCount).toEventually(equal(32))
                
                UserDefaults.standard.selectedOnlineLayers = ["1": []]
                expect(testimpl.mapView?.overlays.count).toEventually(equal(0))
                
                mixin.cleanupMixin()
            }
        }
    }
}
