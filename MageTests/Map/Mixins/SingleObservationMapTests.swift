//
//  SingleObservationMapTests.swift
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

@testable import MAGE
import CoreLocation
import MapKit

class SingleObservationMapTestImpl : NSObject, FilteredObservationsMap {
    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
    
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?

    var singleObservationMapMixin: SingleObservationMapMixin?
}

extension SingleObservationMapTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return singleObservationMapMixin?.renderer(overlay: overlay) ?? singleObservationMapMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return singleObservationMapMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class SingleObservationMapTests: KIFSpec {
    
    override func spec() {
        
        describe("SingleObservationMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: SingleObservationMapTestImpl!
            var mixin: SingleObservationMapMixin!
            var userabc: User!
            
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
                UserDefaults.standard.selectedOnlineLayers = nil
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                Server.setCurrentEventId(1);
                
                controller = UIViewController()
                let mapView = MKMapView()
                controller.view = mapView
                
                testimpl = SingleObservationMapTestImpl()
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
            
            it("initialize the SingleObservationMap with an observation") {
                let observation = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                
                mixin = SingleObservationMapMixin(filteredObservationsMap: testimpl, observation: observation)
                testimpl.singleObservationMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 20, longitude: 15), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }
                
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(20.0000, within: 0.1))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(15.0000, within: 0.1))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the SingleObservationMap with an observation and update location") {
                let observation = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                
                mixin = SingleObservationMapMixin(filteredObservationsMap: testimpl, observation: observation)
                testimpl.singleObservationMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 20, longitude: 15), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }
                
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(20.0000, within: 0.1))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(15.0000, within: 0.1))
                
                observation.geometry = SFPoint(x: 20, andY: 30)
                
                expect(((testimpl.mapView?.annotations[0] as? ObservationAnnotation)?.observation?.geometry as? SFPoint)?.x.intValue).toEventually(equal(20))
                expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation
                expect(oa?.observation).to(equal(observation))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the SingleObservationMap with an observation and then change observation") {
                let observation = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                
                mixin = SingleObservationMapMixin(filteredObservationsMap: testimpl, observation: observation)
                testimpl.singleObservationMapMixin = mixin
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 20, longitude: 15), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }
                
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(20.0000, within: 0.1))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(15.0000, within: 0.1))
                
                let observation2 = Observation.create(geometry: SFPoint(x: 20, andY: 30), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                
                mixin.observation = observation2
                expect(((testimpl.mapView?.annotations[0] as? ObservationAnnotation)?.observation?.geometry as? SFPoint)?.x.intValue).toEventually(equal(20))
                expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation
                expect(oa?.observation).to(equal(observation2))
                
                mixin.cleanupMixin()
            }
        }
    }
}
