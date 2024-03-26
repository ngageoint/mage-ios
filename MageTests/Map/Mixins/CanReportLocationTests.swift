//
//  CanReportLocationTests.swift
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

@testable import MAGE
import CoreLocation
import MapKit

class CanReportLocationTestImpl : NSObject, CanReportLocation {
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?
    var navigationController: UINavigationController?
    var canReportLocationMixin: CanReportLocationMixin?
}

class CanReportLocationTests: KIFSpec {
    
    override func spec() {
        
        describe("CanReportLocationTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: CanReportLocationTestImpl!
            var mixin: CanReportLocationMixin!
            var mockCLLocationManager: MockCLLocationManager!
            
            var buttonStack: UIStackView!
            
            describe("User not in the event") {
                
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
                    
                    testimpl = CanReportLocationTestImpl()
                    testimpl.mapView = mapView
                    testimpl.navigationController = navController
                    testimpl.scheme = MAGEScheme.scheme()
                    
                    mockCLLocationManager = MockCLLocationManager()
                    mixin = CanReportLocationMixin(canReportLocation: testimpl, buttonParentView: buttonStack, locationManager: mockCLLocationManager)
                    
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
                it("initialize the CanCreateObservation and press the report location button location authorized") {
                    UserDefaults.standard.reportLocation = true
                    mockCLLocationManager.authorizationStatus = .authorizedAlways
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                    tester().waitForView(withAccessibilityLabel: "report location")
                    let button = viewTester().usingLabel("report location").view as! MDCFloatingButton
                    expect(button.currentImage).to(equal(UIImage(named:"location_tracking_off")))
                    expect(button.tintColor).to(equal(MAGEScheme.scheme().colorScheme.onSurfaceColor.withAlphaComponent(0.3)))
                    
                    tester().tapView(withAccessibilityLabel: "report location")
                    tester().waitForView(withAccessibilityLabel: "You cannot report your location for an event you are not part of")
                    expect(button.currentImage).to(equal(UIImage(named:"location_tracking_off")))
                                        
                    mixin.cleanupMixin()
                }
                
                it("initialize the CanCreateObservation and press the report location button location not authorized") {
                    UserDefaults.standard.reportLocation = true
                    mockCLLocationManager.authorizationStatus = .denied
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                    tester().waitForView(withAccessibilityLabel: "report location")
                    let button = viewTester().usingLabel("report location").view as! MDCFloatingButton
                    expect(button.currentImage).to(equal(UIImage(named:"location_tracking_off")))
                    
                    tester().tapView(withAccessibilityLabel: "report location")
                    tester().waitForView(withAccessibilityLabel: "Location Services Disabled")
                    expect(button.currentImage).to(equal(UIImage(named:"location_tracking_off")))
                    
                    // TODO: figure out how to test this
                    // tapping the button works fine, but there is now way to verify that the settings screen opened
//                  tester().tapView(withAccessibilityLabel: "Settings")
                    // in the mean time do this
                    tester().tapView(withAccessibilityLabel: "Cancel")
                    mixin.cleanupMixin()
                }
            }
            
            describe("User in the event") {
                
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
                    
                    testimpl = CanReportLocationTestImpl()
                    testimpl.mapView = mapView
                    testimpl.navigationController = navController
                    
                    mockCLLocationManager = MockCLLocationManager()
                    mixin = CanReportLocationMixin(canReportLocation: testimpl, buttonParentView: buttonStack, locationManager: mockCLLocationManager)
                    
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
                
                it("initialize the CanCreateObservation with the button at index 0") {
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                    tester().waitForView(withAccessibilityLabel: "report location")
                    expect(buttonStack.arrangedSubviews[0]).to(beAKindOf(MDCFloatingButton.self))
                    
                    mixin.cleanupMixin()
                }
                
                it("initialize the CanCreateObservation with the button at index 1") {
                    buttonStack.addArrangedSubview(UIView())
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                    tester().waitForView(withAccessibilityLabel: "report location")
                    expect(buttonStack.arrangedSubviews[1]).to(beAKindOf(MDCFloatingButton.self))
                    
                    mixin.cleanupMixin()
                }
                
                it("initialize the CanCreateObservation and press the report location button location authorized") {
                    UserDefaults.standard.reportLocation = true
                    mockCLLocationManager.authorizationStatus = .authorizedAlways
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                    tester().waitForView(withAccessibilityLabel: "report location")
                    let button = viewTester().usingLabel("report location").view as! MDCFloatingButton
                    expect(button.currentImage).to(equal(UIImage(named:"location_tracking_on")))
                    
                    tester().tapView(withAccessibilityLabel: "report location")
                    tester().waitForView(withAccessibilityLabel: "Location reporting has been disabled")
                    expect(button.currentImage).to(equal(UIImage(named:"location_tracking_off")))
                    expect(UserDefaults.standard.reportLocation).to(beFalse())
                    
                    tester().tapView(withAccessibilityLabel: "report location")
                    tester().waitForView(withAccessibilityLabel: "You are now reporting your location")
                    expect(button.currentImage).to(equal(UIImage(named:"location_tracking_on")))
                    expect(UserDefaults.standard.reportLocation).to(beTrue())
                                        
                    mixin.cleanupMixin()
                }
                
                it("initialize the CanCreateObservation and press the report location button location not authorized") {
                    UserDefaults.standard.reportLocation = true
                    mockCLLocationManager.authorizationStatus = .denied
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    
                    tester().waitForView(withAccessibilityLabel: "report location")
                    let button = viewTester().usingLabel("report location").view as! MDCFloatingButton
                    expect(button.currentImage).to(equal(UIImage(named:"location_tracking_off")))
                    
                    tester().tapView(withAccessibilityLabel: "report location")
                    tester().waitForView(withAccessibilityLabel: "Location Services Disabled")
                    expect(button.currentImage).to(equal(UIImage(named:"location_tracking_off")))
                    
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
}
