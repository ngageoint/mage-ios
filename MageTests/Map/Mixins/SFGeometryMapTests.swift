//
//  SFGeometryMapTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/22/22.
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

class SFGeometryMapTestImpl : NSObject, SFGeometryMap {
    var mapView: MKMapView?
    var scheme: AppContainerScheming?
    
    var sfGeometryMapMixin: SFGeometryMapMixin?
}

extension SFGeometryMapTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return sfGeometryMapMixin?.renderer(overlay: overlay) ?? sfGeometryMapMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return sfGeometryMapMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class SFGeometryMapTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("SFGeometryMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: SFGeometryMapTestImpl!
            var mixin: SFGeometryMapMixin!
            var userabc: User!
            var coreDataStack: TestCoreDataStack?
            var context: NSManagedObjectContext!
            
            beforeEach {
                coreDataStack = TestCoreDataStack()
                context = coreDataStack!.persistentContainer.newBackgroundContext()
                InjectedValues[\.nsManagedObjectContext] = context
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
                UserDefaults.standard.selectedOnlineLayers = nil
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                Server.setCurrentEventId(1);
                
                controller = UIViewController()
                let mapView = MKMapView()
                controller.view = mapView
                
                testimpl = SFGeometryMapTestImpl()
                testimpl.mapView = mapView
                testimpl.scheme = MAGEScheme.scheme()
                mapView.delegate = testimpl
                
                navController = UINavigationController(rootViewController: controller);
                
                window.rootViewController = navController;
                
                view = window
                if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                    window.overrideUserInterfaceStyle = .unspecified
                }
            }
            
            afterEach {
                InjectedValues[\.nsManagedObjectContext] = nil
                coreDataStack!.reset()
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
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs()
            }

            it("initialize the SFGeometryMap with point") {
                let geometry = SFPoint(xValue: -104.1, andYValue: 40.1)
                mixin = SFGeometryMapMixin(sfGeometryMap: testimpl, sfGeometry: geometry)
                testimpl.sfGeometryMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(1))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the SFGeometryMap then set point") {
                let geometry = SFPoint(xValue: -104.1, andYValue: 40.1)
                mixin = SFGeometryMapMixin(sfGeometryMap: testimpl, sfGeometry: nil)
                testimpl.sfGeometryMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                
                mixin.sfGeometry = geometry
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(1))
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(40.1, within: 0.01))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(-104.1, within: 0.01))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the SFGeometryMap then set line") {
                let geometry = SFLineString(points: [SFPoint(x: 15, andY: 22) as Any, SFPoint(x: 17, andY: 20) as Any])
                mixin = SFGeometryMapMixin(sfGeometryMap: testimpl, sfGeometry: nil)
                testimpl.sfGeometryMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                
                mixin.sfGeometry = geometry
                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                let centroid = geometry?.centroid()
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(centroid!.y.doubleValue, within: 0.5))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(centroid!.x.doubleValue, within: 0.5))
                mixin.cleanupMixin()
            }
            
            it("initialize the SFGeometryMap then set polygon") {
                let geometry = SFPolygon(ring: SFLineString(points: [SFPoint(x: 16.1, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 21.1) as Any]))
                mixin = SFGeometryMapMixin(sfGeometryMap: testimpl, sfGeometry: nil)
                testimpl.sfGeometryMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                
                mixin.sfGeometry = geometry
                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                let centroid = geometry?.centroid()
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(centroid!.y.doubleValue, within: 0.5))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(centroid!.x.doubleValue, within: 0.5))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the SFGeometryMap then set polygon with options") {
                let geometry = SFPolygon(ring: SFLineString(points: [SFPoint(x: 16.1, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 21.1) as Any]))
                mixin = SFGeometryMapMixin(sfGeometryMap: testimpl, sfGeometry: nil)
                testimpl.sfGeometryMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                
                mixin.sfGeometry = geometry
                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                let centroid = geometry?.centroid()
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(centroid!.y.doubleValue, within: 0.5))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(centroid!.x.doubleValue, within: 0.5))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the SFGeometryMap then set polygon then replace it with a point") {
                let geometry = SFPolygon(ring: SFLineString(points: [SFPoint(x: 16.1, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 21.1) as Any]))
                mixin = SFGeometryMapMixin(sfGeometryMap: testimpl, sfGeometry: nil)
                testimpl.sfGeometryMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                
                mixin.sfGeometry = geometry
                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                let centroid = geometry?.centroid()
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(centroid!.y.doubleValue, within: 0.5))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(centroid!.x.doubleValue, within: 0.5))
                
                let point = SFPoint(xValue: -104.1, andYValue: 40.1)
                mixin.replaceSFGeometry(sfGeometry: point)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(1))
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(40.1, within: 0.01))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(-104.1, within: 0.01))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the SFGeometryMap then set polygon then replace it with a point in setter") {
                let geometry = SFPolygon(ring: SFLineString(points: [SFPoint(x: 16.1, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 21.1) as Any]))
                mixin = SFGeometryMapMixin(sfGeometryMap: testimpl, sfGeometry: nil)
                testimpl.sfGeometryMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                
                mixin.sfGeometry = geometry
                expect(testimpl.mapView?.overlays.count).to(equal(1))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                let centroid = geometry?.centroid()
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(centroid!.y.doubleValue, within: 0.5))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(centroid!.x.doubleValue, within: 0.5))
                
                let point = SFPoint(xValue: -104.1, andYValue: 40.1)
                mixin.sfGeometry = point
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(1))
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(40.1, within: 0.01))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(-104.1, within: 0.01))
                
                mixin.cleanupMixin()
            }
        }
    }
}
