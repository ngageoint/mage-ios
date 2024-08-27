//
//  PersistedMapStateTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/10/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs
import MagicalRecord
import MapFramework

@testable import MAGE
import CoreLocation
import MapKit

class PersistedMapStateTestImpl : NSObject {
    var mapView: MKMapView?
    
    var persistedMapStateMixin: PersistedMapStateMixin?
}

class PersistedMapStateTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("PersistedMapStateTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: PersistedMapStateTestImpl!
            var mixin: PersistedMapStateMixin!
            
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

                controller = UIViewController()
                let mapView = MKMapView()
                controller.view = mapView
                
                testimpl = PersistedMapStateTestImpl()
                testimpl.mapView = mapView
                
                // TODO: inject a different map state repository
                mixin = PersistedMapStateMixin()
                
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
                HTTPStubs.removeAllStubs();
                
            }
            
            it("initialize the PersistedMapState with a region") {
                UserDefaults.standard.mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 30, longitude: 10), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                expect(testimpl.mapView!.centerCoordinate.latitude).toEventually(beCloseTo(30, within: 1.0))
                expect(testimpl.mapView!.centerCoordinate.longitude).toEventually(beCloseTo(10, within: 1.0))
                mixin.cleanupMixin()
            }
            
            it("initialize the PersistedMapState with a region then move the map and the user preference should change") {
                UserDefaults.standard.mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 30, longitude: 10), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                
                expect(testimpl.mapView!.centerCoordinate.latitude).toEventually(beCloseTo(30, within: 1.0))
                expect(testimpl.mapView!.centerCoordinate.longitude).toEventually(beCloseTo(10, within: 1.0))
                
                let region = testimpl.mapView!.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:15, longitude:25), latitudinalMeters: 100000, longitudinalMeters: 10000))
                testimpl.mapView!.setRegion(region, animated: false)
                
//                mixin.regionDidChange(mapView: testimpl.mapView!, animated: false)
                
                let newRegion = UserDefaults.standard.mapRegion
                expect(newRegion.center.latitude).to(beCloseTo(15, within: 1))
                expect(newRegion.center.longitude).to(beCloseTo(25, within: 1))
                mixin.cleanupMixin()
            }
        }
    }
}
