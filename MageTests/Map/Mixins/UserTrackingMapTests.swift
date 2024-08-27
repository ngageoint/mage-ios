//
//  UserTrackingMapTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/11/22.
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

class UserTrackingMapTestImpl : NSObject, UserTrackingMap {
    var mapView: MKMapView?
    var navigationController: UINavigationController?
    var userTrackingMapMixin: UserTrackingMapMixin?
}

class UserTrackingMapTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("UserTrackingMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: UserTrackingMapTestImpl!
            var mixin: UserTrackingMapMixin!
            var mockCLLocationManager: MockCLLocationManager!
            
            var buttonStack: UIStackView!
        
                
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
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                
                Server.setCurrentEventId(1);
                
                let mapView = MKMapView()
                
                controller = UIViewController()
                controller.view.addSubview(mapView)
                mapView.autoPinEdgesToSuperviewEdges()
                
                buttonStack = UIStackView.newAutoLayout()
                buttonStack.axis = .vertical
                buttonStack.alignment = .fill
                buttonStack.spacing = 0
                buttonStack.distribution = .fill
                
                controller.view.addSubview(buttonStack)
                buttonStack.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
                
                navController = UINavigationController(rootViewController: controller);
                
                testimpl = UserTrackingMapTestImpl()
                testimpl.mapView = mapView
                testimpl.navigationController = navController
                
                mockCLLocationManager = MockCLLocationManager()
                mixin = UserTrackingMapMixin(userTrackingMap: testimpl, buttonParentView: buttonStack, locationManager: mockCLLocationManager, scheme: MAGEScheme.scheme())
                
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
                HTTPStubs.removeAllStubs()
            }
            
            it("initialize the UserTrackingMap with the button at index 0") {
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                tester().waitForView(withAccessibilityLabel: "track location")
                expect(buttonStack.arrangedSubviews[0]).to(beAKindOf(MDCFloatingButton.self))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the UserTrackingMap and press the track location button location authorized") {
                mixin.mapView?.userTrackingMode = .none
                mockCLLocationManager.authorizationStatus = .authorizedAlways
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                tester().waitForView(withAccessibilityLabel: "track location")
                let button = viewTester().usingLabel("track location").view as! MDCFloatingButton
                expect(button.currentImage).to(equal(UIImage(systemName: "location")))
                expect(mixin.mapView?.userTrackingMode).to(equal(MKUserTrackingMode.none))
                
                tester().tapView(withAccessibilityLabel: "track location")
                expect(button.currentImage).to(equal(UIImage(systemName: "location.fill")))
                expect(mixin.mapView?.userTrackingMode).to(equal(.follow))

                tester().tapView(withAccessibilityLabel: "track location")
                expect(button.currentImage).to(equal(UIImage(systemName: "location.north.line.fill")))
                expect(mixin.mapView?.userTrackingMode).to(equal(.followWithHeading))

                tester().tapView(withAccessibilityLabel: "track location")
                expect(button.currentImage).to(equal(UIImage(systemName: "location")))
                expect(mixin.mapView?.userTrackingMode).to(equal(MKUserTrackingMode.none))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the UserTrackingMap and press the track location button location not authorized") {
                mixin.mapView?.userTrackingMode = .none
                mockCLLocationManager.authorizationStatus = .denied
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                
                tester().waitForView(withAccessibilityLabel: "track location")
                let button = viewTester().usingLabel("track location").view as! MDCFloatingButton
                expect(button.currentImage).to(equal(UIImage(systemName: "location")))
                expect(mixin.mapView?.userTrackingMode).to(equal(MKUserTrackingMode.none))
                
                tester().tapView(withAccessibilityLabel: "track location")
                tester().waitForView(withAccessibilityLabel: "Location Services Disabled")
                expect(button.currentImage).to(equal(UIImage(systemName: "location")))
                
                // TODO: figure out how to test this
                // tapping the button works fine, but there is now way to verify that the settings screen opened
                //                tester().tapView(withAccessibilityLabel: "Settings")
                // in the mean time do this
                tester().tapView(withAccessibilityLabel: "Cancel")
                
                mixin.cleanupMixin()
            }
        }
    }
}
