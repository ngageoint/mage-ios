//
//  BottomSheetMixinTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/23/22.
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

class BottomSheetEnabledTestImpl : NSObject, BottomSheetEnabled {
    var mapView: MKMapView?
    var bottomSheetMixin: BottomSheetMixin?
}

class BottomSheetEnabledTests: KIFSpec {
    
    override func spec() {
        
        describe("BottomSheetEnabledTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: BottomSheetEnabledTestImpl!
            var mixin: BottomSheetMixin!
            
            var mapStack: UIStackView!
            
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
                UserDefaults.standard.observationTimeFilter = .all
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                Server.setCurrentEventId(1);
                
                let mapView = MKMapView()

                controller = UIViewController()
                controller.view.addSubview(mapView)
                mapView.autoPinEdgesToSuperviewEdges()
                
                mapStack = UIStackView.newAutoLayout()
                mapStack.axis = .vertical
                mapStack.alignment = .fill
                mapStack.spacing = 0
                mapStack.distribution = .fill
                
                controller.view.addSubview(mapStack)
                mapStack.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
                
                testimpl = BottomSheetEnabledTestImpl()
                testimpl.mapView = mapView
                
                navController = UINavigationController(rootViewController: controller);
                
                mixin = BottomSheetMixin(mapView: mapView, navigationController: navController, scheme: MAGEScheme.scheme())
                testimpl.bottomSheetMixin = mixin
                
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
            
            it("observation bottom sheet") {
                let observation = MageCoreDataFixtures.addObservationToEvent()!
                let oa = ObservationAnnotation(observation: observation, geometry: observation.geometry)
                
                mixin.setupMixin()

                let notification = MapItemsTappedNotification(annotations: [oa], items: nil, mapView: mixin.mapView)
                NotificationCenter.default.post(name: .MapItemsTapped, object: notification)
                
                tester().waitForView(withAccessibilityLabel: "At Venue")
                
                NotificationCenter.default.post(name: .DismissBottomSheet, object: nil)
                tester().waitForAbsenceOfView(withAccessibilityLabel: "At Venue")
                
                mixin.cleanupMixin()
            }
            
            it("user bottom sheet") {
                MageCoreDataFixtures.addUser()
                let location = MageCoreDataFixtures.addLocation()
                let ua = LocationAnnotation(location: location)
                
                mixin.setupMixin()
                
                let notification = MapItemsTappedNotification(annotations: [ua], items: nil, mapView: mixin.mapView)
                NotificationCenter.default.post(name: .MapItemsTapped, object: notification)
                
                tester().waitForView(withAccessibilityLabel: "User ABC")
                tester().tapScreen(at: CGPoint.zero)
                tester().waitForAbsenceOfView(withAccessibilityLabel: "User ABC")
                
                mixin.cleanupMixin()
            }
            
            it("static point bottom sheet") {
                let feature: [AnyHashable: Any] = [
                        "type": "Feature",
                        "geometry": [
                            "type": "Point",
                            "coordinates":
                            [
                                -104.75,
                                 39.7
                            ]
                            
                        ],
                        "properties": [
                            "name": "Point",
                            "description": "<i>It's a point</i>",
                            "style": [
                                "iconStyle": [
                                    "scale": "1.1",
                                    "icon": [
                                        "href": "https://magetest/testkmlicon.png"
                                    ]
                                ],
                                "lineStyle": nil,
                                "labelStyle": nil,
                                "polyStyle": nil
                            ]
                        ],
                        "id": "point"
                ]
                
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
                
                let sa = StaticPointAnnotation(feature: feature)
                
                mixin.setupMixin()
                
                let notification = MapItemsTappedNotification(annotations: [sa], items: nil, mapView: mixin.mapView)
                NotificationCenter.default.post(name: .MapItemsTapped, object: notification)
                
                tester().waitForView(withAccessibilityLabel: "Point")
                expect(iconStubCalled).toEventually(beTrue())
                
                NotificationCenter.default.post(name: .MapViewDisappearing, object: nil)
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Point")
                
                mixin.cleanupMixin()
            }
            
            it("feed item bottom sheet") {
                MageCoreDataFixtures.addFeedToEvent()
                let feedItem = MageCoreDataFixtures.addFeedItemToFeed(simpleFeature: SFPoint(x: -105, andY: 40.01))
                
                mixin.setupMixin()
                
                let notification = MapItemsTappedNotification(annotations: [feedItem], items: nil, mapView: mixin.mapView)
                NotificationCenter.default.post(name: .MapItemsTapped, object: notification)
                
                tester().waitForView(withAccessibilityLabel: "No Content")
                
                mixin.cleanupMixin()
            }
            
            it("multiple items bottom sheet") {
                let feature: [AnyHashable: Any] = [
                    "type": "Feature",
                    "geometry": [
                        "type": "Point",
                        "coordinates":
                            [
                                -104.75,
                                 39.7
                            ]
                        
                    ],
                    "properties": [
                        "name": "Point",
                        "description": "<i>It's a point</i>",
                        "style": [
                            "iconStyle": [
                                "scale": "1.1",
                                "icon": [
                                    "href": "https://magetest/testkmlicon.png"
                                ]
                            ],
                            "lineStyle": nil,
                            "labelStyle": nil,
                            "polyStyle": nil
                        ]
                    ],
                    "id": "point"
                ]
                
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
                
                let sa = StaticPointAnnotation(feature: feature)
                MageCoreDataFixtures.addFeedToEvent()
                let feedItem = MageCoreDataFixtures.addFeedItemToFeed(simpleFeature: SFPoint(x: -105, andY: 40.01))
                
                MageCoreDataFixtures.addUser()
                let location = MageCoreDataFixtures.addLocation()
                let ua = LocationAnnotation(location: location)
                
                let observation = MageCoreDataFixtures.addObservationToEvent()!
                let oa = ObservationAnnotation(observation: observation, geometry: observation.geometry)
                
                let lineObs = ObservationBuilder.createLineObservation()
                lineObs.properties!["forms"] = [
                    [
                        "formId": 1,
                        "field0": "Something Cool"
                    ]
                ]
                
                let polygonObs = ObservationBuilder.createPolygonObservation()
                polygonObs.properties!["forms"] = [
                    [
                        "formId": 1,
                        "field0": "Super Cool"
                    ]
                ]
                
                
                mixin.setupMixin()
                
                let notification = MapItemsTappedNotification(annotations: [oa, ua, sa, feedItem], items: [lineObs,polygonObs], mapView: mixin.mapView)
                NotificationCenter.default.post(name: .MapItemsTapped, object: notification)
                
                tester().waitForView(withAccessibilityLabel: "At Venue")
                tester().tapView(withAccessibilityLabel: "next_feature")
                tester().waitForView(withAccessibilityLabel: "User ABC")
                tester().tapView(withAccessibilityLabel: "next_feature")
                tester().waitForView(withAccessibilityLabel: "Point")
                tester().tapView(withAccessibilityLabel: "next_feature")
                tester().waitForView(withAccessibilityLabel: "No Content")
                tester().tapView(withAccessibilityLabel: "next_feature")
                tester().waitForView(withAccessibilityLabel: "Something Cool")
                tester().tapView(withAccessibilityLabel: "next_feature")
                tester().waitForView(withAccessibilityLabel: "Super Cool")
                tester().tapView(withAccessibilityLabel: "previous_feature")
                tester().waitForView(withAccessibilityLabel: "Something Cool")
                tester().tapView(withAccessibilityLabel: "previous_feature")
                tester().waitForView(withAccessibilityLabel: "No Content")
                tester().tapView(withAccessibilityLabel: "previous_feature")
                tester().waitForView(withAccessibilityLabel: "Point")
                tester().tapView(withAccessibilityLabel: "previous_feature")
                tester().waitForView(withAccessibilityLabel: "User ABC")
                tester().tapView(withAccessibilityLabel: "previous_feature")
                tester().waitForView(withAccessibilityLabel: "At Venue")
                expect(iconStubCalled).toEventually(beTrue())

                mixin.cleanupMixin()
            }

        }
    }
}
