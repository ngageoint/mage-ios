//
//  UserHeadingDisplayTests.swift
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

class UserHeadingDisplayTestImpl : NSObject, UserHeadingDisplay {
    var mapView: MKMapView?
    var navigationController: UINavigationController?
    var userHeadingDisplayMixin: UserHeadingDisplayMixin?
}

extension UserHeadingDisplayTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return userHeadingDisplayMixin?.renderer(overlay: overlay) ?? userHeadingDisplayMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return userHeadingDisplayMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

//class UserHeadingDisplayTests: KIFSpec {
//    
//    override func spec() {
//        
//        xdescribe("UserHeadingDisplayTests") {
//            var navController: UINavigationController!
//            var view: UIView!
//            var window: UIWindow!;
//            var controller: UIViewController!
//            var testimpl: UserHeadingDisplayTestImpl!
//            var mixin: UserHeadingDisplayMixin!
//            var mockCLLocationManager: MockCLLocationManager!
//            
//            var mapStack: UIStackView!
//            var coreDataStack: TestCoreDataStack?
//            var context: NSManagedObjectContext!
//            
//            
//            beforeEach {
//                coreDataStack = TestCoreDataStack()
//                context = coreDataStack!.persistentContainer.newBackgroundContext()
//                InjectedValues[\.nsManagedObjectContext] = context
//                if (navController != nil) {
//                    waitUntil { done in
//                        navController.dismiss(animated: false, completion: {
//                            done();
//                        });
//                    }
//                }
//                TestHelpers.clearAndSetUpStack();
//                if (view != nil) {
//                    for subview in view.subviews {
//                        subview.removeFromSuperview();
//                    }
//                }
//                window = TestHelpers.getKeyWindowVisible();
//                UserDefaults.standard.mapType = 0;
//                UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
//                
//                UserDefaults.standard.baseServerUrl = "https://magetest";
//                
//                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
//                MageCoreDataFixtures.addUser(userId: "userabc")
//                UserDefaults.standard.currentUserId = "userabc";
//                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
//                
//                Server.setCurrentEventId(1);
//                
//                let mapView = MKMapView()
//                
//                controller = UIViewController()
//                controller.view.addSubview(mapView)
//                mapView.autoPinEdgesToSuperviewEdges()
//                
//                mapStack = UIStackView.newAutoLayout()
//                mapStack.axis = .vertical
//                mapStack.alignment = .fill
//                mapStack.spacing = 0
//                mapStack.distribution = .fill
//                
//                controller.view.addSubview(mapStack)
//                mapStack.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
//                
//                navController = UINavigationController(rootViewController: controller);
//                
//                testimpl = UserHeadingDisplayTestImpl()
//                testimpl.mapView = mapView
//                testimpl.navigationController = navController
//                
//                mockCLLocationManager = MockCLLocationManager()
//                mixin = UserHeadingDisplayMixin(userHeadingDisplay: testimpl, mapStack: mapStack, locationManager: mockCLLocationManager, scheme: MAGEScheme.scheme())
//                testimpl.userHeadingDisplayMixin = mixin
//                
//                window.rootViewController = navController;
//                
//                view = window
//                if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
//                    window.overrideUserInterfaceStyle = .unspecified
//                }
//            }
//            
//            afterEach {
//                InjectedValues[\.nsManagedObjectContext] = nil
//                coreDataStack!.reset()
//                mixin = nil
//                testimpl = nil
//                
//                for subview in view.subviews {
//                    subview.removeFromSuperview();
//                }
//                waitUntil { done in
//                    controller.dismiss(animated: false, completion: {
//                        done();
//                    });
//                }
//                UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
//                
//                if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
//                    window.overrideUserInterfaceStyle = .unspecified
//                }
//                window?.resignKey();
//                window.rootViewController = nil;
//                navController = nil;
//                view = nil;
//                window = nil;
//                TestHelpers.clearAndSetUpStack();
//                HTTPStubs.removeAllStubs()
//            }
//            
//
//            it("initialize the UserHeadingDisplay and change the map tracking mode with showHeadingSet false") {
//                UserDefaults.standard.removeObject(forKey: #keyPath(UserDefaults.showHeading))
//                mixin.mapView?.userTrackingMode = .none
//                mockCLLocationManager.authorizationStatus = .authorizedAlways
//                
//                let mapState = MapState()
//                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//                mixin.mapView?.userTrackingMode = .follow
//                mixin.didChangeUserTrackingMode(mapView: mixin.mapView!, animated: false)
//                
//                tester().waitForView(withAccessibilityLabel: "Display Your Heading")
//                tester().tapView(withAccessibilityLabel: "No")
//                
//                expect(UserDefaults.standard.showHeadingSet).to(beTrue())
//                expect(UserDefaults.standard.showHeading).to(beFalse())
//                expect(mockCLLocationManager.updatingLocation).to(beFalse())
//                expect(mockCLLocationManager.updatingHeading).to(beFalse())
//                
//                mixin.cleanupMixin()
//            }
//            
//            it("initialize the UserHeadingDisplay and change the map tracking mode with showHeadingSet false then start") {
//                UserDefaults.standard.removeObject(forKey: #keyPath(UserDefaults.showHeading))
//                mixin.mapView?.userTrackingMode = .none
//                mockCLLocationManager.authorizationStatus = .authorizedAlways
//                
//                mixin.mapView?.delegate = testimpl
//                
//                let mapState = MapState()
//                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//                mixin.mapView?.userTrackingMode = .follow
//                mixin.didChangeUserTrackingMode(mapView: mixin.mapView!, animated: false)
//                
//                tester().waitForView(withAccessibilityLabel: "Display Your Heading")
//                tester().tapView(withAccessibilityLabel: "Yes")
//                
//                expect(UserDefaults.standard.showHeadingSet).to(beTrue())
//                expect(UserDefaults.standard.showHeading).to(beTrue())
//                expect(mockCLLocationManager.updatingLocation).to(beTrue())
//                expect(mockCLLocationManager.updatingHeading).to(beTrue())
//                
//                expect(mixin.mapView?.overlays.count).to(equal(1))
//                expect(mixin.mapView?.overlays[0]).to(beAKindOf(NavigationOverlay.self))
//                                
//                mixin.cleanupMixin()
//            }
//            
//            it("initialize the UserHeadingDisplay and change the map tracking mode to followWithHeading with showHeadingSet false then start") {
//                UserDefaults.standard.removeObject(forKey: #keyPath(UserDefaults.showHeading))
//                mixin.mapView?.userTrackingMode = .none
//                mockCLLocationManager.authorizationStatus = .authorizedAlways
//                
//                mixin.mapView?.delegate = testimpl
//                
//                let mapState = MapState()
//                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//                mixin.mapView?.userTrackingMode = .followWithHeading
//                mixin.didChangeUserTrackingMode(mapView: mixin.mapView!, animated: false)
//                
//                tester().waitForView(withAccessibilityLabel: "Display Your Heading")
//                tester().tapView(withAccessibilityLabel: "Yes")
//                
//                expect(UserDefaults.standard.showHeadingSet).to(beTrue())
//                expect(UserDefaults.standard.showHeading).to(beTrue())
//                expect(mockCLLocationManager.updatingLocation).to(beTrue())
//                expect(mockCLLocationManager.updatingHeading).to(beTrue())
//                
//                expect(mixin.mapView?.overlays.count).to(equal(1))
//                expect(mixin.mapView?.overlays[0]).to(beAKindOf(NavigationOverlay.self))
//                
//                mixin.cleanupMixin()
//            }
//            
//            it("initialize the UserHeadingDisplay and then stop") {
//                UserDefaults.standard.removeObject(forKey: #keyPath(UserDefaults.showHeading))
//                mixin.mapView?.userTrackingMode = .none
//                mockCLLocationManager.authorizationStatus = .authorizedAlways
//                
//                mixin.mapView?.delegate = testimpl
//                
//                let mapState = MapState()
//                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//                mixin.mapView?.userTrackingMode = .followWithHeading
//                mixin.didChangeUserTrackingMode(mapView: mixin.mapView!, animated: false)
//                
//                tester().waitForView(withAccessibilityLabel: "Display Your Heading")
//                tester().tapView(withAccessibilityLabel: "Yes")
//                
//                expect(UserDefaults.standard.showHeadingSet).to(beTrue())
//                expect(UserDefaults.standard.showHeading).to(beTrue())
//                expect(mockCLLocationManager.updatingLocation).to(beTrue())
//                expect(mockCLLocationManager.updatingHeading).to(beTrue())
//                
//                expect(mixin.mapView?.overlays.count).to(equal(1))
//                expect(mixin.mapView?.overlays[0]).to(beAKindOf(NavigationOverlay.self))
//                
//                mixin.stop()
//                expect(mockCLLocationManager.updatingLocation).to(beFalse())
//                expect(mockCLLocationManager.updatingHeading).to(beFalse())
//                expect(mixin.mapView?.overlays.count).to(equal(0))
//                
//                mixin.cleanupMixin()
//            }
//            
//        }
//    }
//}
