//
//  FilteredObservationsMapTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/8/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs
import MagicalRecord
import XCTest

@testable import MAGE

class FilteredObservationsMapTestImpl : NSObject, FilteredObservationsMap {
    var scheme: MDCContainerScheming?
    var mapView: MKMapView?
    
    var filteredObservationsMapMixin: FilteredObservationsMapMixin?
}

extension FilteredObservationsMapTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return filteredObservationsMapMixin?.renderer(overlay: overlay) ?? filteredObservationsMapMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return filteredObservationsMapMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class FilteredObservationsMapTests: KIFSpec {
    
    override func spec() {
        
        describe("FilteredObservationsMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: FilteredObservationsMapTestImpl!
            var fomixin: FilteredObservationsMapMixin!
            
            describe("show observations for user") {
                
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
                    UserDefaults.standard.themeOverride = 0;
                    UserDefaults.standard.locationDisplay = .latlng;
                    
                    expect(Observation.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations still exist in default");
                    
                    expect(Observation.mr_findAll(in: NSManagedObjectContext.mr_rootSaving())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations still exist in root");
                    UserDefaults.standard.baseServerUrl = "https://magetest";
                    
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                    let user = MageCoreDataFixtures.addUser(userId: "userabc")
                    MageCoreDataFixtures.addUser(userId: "userdef")
                    MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                    MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userdef")
                    Server.setCurrentEventId(1);
                    UserDefaults.standard.currentUserId = "userabc";
                    
                    
                    controller = UIViewController()
                    let mapView = MKMapView()
                    controller.view = mapView
                    
                    testimpl = FilteredObservationsMapTestImpl()
                    testimpl.mapView = mapView
                    testimpl.scheme = MAGEScheme.scheme()
                    
                    fomixin = FilteredObservationsMapMixin(filteredObservationsMap: testimpl, user: user)
                    testimpl.filteredObservationsMapMixin = fomixin
                    
                    navController = UINavigationController(rootViewController: controller);
                    window.rootViewController = navController;
                    
                    view = window
                    if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                        window.overrideUserInterfaceStyle = .unspecified
                    }
                }
                
                afterEach {
                    fomixin = nil
                    testimpl = nil
                    
                    for subview in view.subviews {
                        subview.removeFromSuperview();
                    }
                    waitUntil { done in
                        controller.dismiss(animated: false, completion: {
                            done();
                        });
                    }
                    UserDefaults.standard.themeOverride = 0
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
                
                it("initialize the FilteredObservationsMap with current user observations") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    _ = Observation.create(geometry: SFPoint(x: 16, andY: 21), date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());

                    _ = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    UserDefaults.standard.currentUserId = "userdef";
                    
                    _ = Observation.create(geometry: SFPoint(x: 14, andY: 21), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    fomixin.setupMixin()
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(2))
                    fomixin.cleanupMixin()
                }
            }
            
            describe("show observations") {
            
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
                    UserDefaults.standard.themeOverride = 0;
                    UserDefaults.standard.locationDisplay = .latlng;
                    
                    expect(Observation.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations still exist in default");
                    
                    expect(Observation.mr_findAll(in: NSManagedObjectContext.mr_rootSaving())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations still exist in root");
                    UserDefaults.standard.baseServerUrl = "https://magetest";
                    
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                    MageCoreDataFixtures.addUser(userId: "userabc")
                    MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                    Server.setCurrentEventId(1);
                    UserDefaults.standard.currentUserId = "userabc";
                    
                    
                    controller = UIViewController()
                    let mapView = MKMapView()
                    controller.view = mapView
                    
                    testimpl = FilteredObservationsMapTestImpl()
                    testimpl.mapView = mapView
                    
                    fomixin = FilteredObservationsMapMixin(filteredObservationsMap: testimpl)
                    testimpl.filteredObservationsMapMixin = fomixin
                    
                    navController = UINavigationController(rootViewController: controller);
                    window.rootViewController = navController;
                    
                    view = window
                    if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                        window.overrideUserInterfaceStyle = .unspecified
                    }
                }
                
                afterEach {
                    fomixin = nil
                    testimpl = nil
                    
                    for subview in view.subviews {
                        subview.removeFromSuperview();
                    }
                    waitUntil { done in
                        controller.dismiss(animated: false, completion: {
                            done();
                        });
                    }
                    UserDefaults.standard.themeOverride = 0
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
                
                it("initialize the FilteredObservationsMap filtering on all") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    _ = Observation.create(geometry: SFPoint(x: 16, andY: 21), date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    _ = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    fomixin.setupMixin()
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(2))
                    fomixin.cleanupMixin()
                }
                
                it("initialize the FilteredObservationsMap filtering on last 24 hours") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    _ = Observation.create(geometry: SFPoint(x: 16, andY: 21), date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    let two = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    UserDefaults.standard.observationTimeFilterKey = .last24Hours
                    
                    fomixin.setupMixin()
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation
                    expect(oa?.observation).to(equal(two))
                    fomixin.cleanupMixin()
                }
                
                it("initialize the FilteredObservationsMap filtering on last week") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    _ = Observation.create(geometry: SFPoint(x: 16, andY: 21), date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    let two = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    UserDefaults.standard.observationTimeFilterKey = .lastWeek
                    
                    fomixin.setupMixin()
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation
                    expect(oa?.observation).to(equal(two))
                    fomixin.cleanupMixin()
                }
                
                it("initialize the FilteredObservationsMap filtering on last month") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    _ = Observation.create(geometry: SFPoint(x: 16, andY: 21), date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    let two = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    UserDefaults.standard.observationTimeFilterKey = .lastWeek
                    
                    fomixin.setupMixin()
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation
                    expect(oa?.observation).to(equal(two))
                    fomixin.cleanupMixin()
                }

                it("initialize the FilteredObservationsMap filtering on all with observations showing up later") {
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    fomixin.setupMixin()
                    
                    let longAgo = Date(timeIntervalSince1970: 1)
                    let one = Observation.create(geometry: SFPoint(x: 16, andY: 21), date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    let two = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(2))
                    
                    one.mr_deleteEntity()
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation
                    expect(oa?.observation).to(equal(two))
                    fomixin.cleanupMixin()
                }
                
                it("initialize the FilteredObservationsMap filtering on all then change filter") {
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    fomixin.setupMixin()
                    
                    let longAgo = Date(timeIntervalSince1970: 1)
                    _ = Observation.create(geometry: SFPoint(x: 16, andY: 21), date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    let two = Observation.create(geometry: SFPoint(x: 15, andY: 20), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(2))
                    
                    UserDefaults.standard.observationTimeFilterKey = .lastWeek
                    
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation
                    expect(oa?.observation).to(equal(two))
                    fomixin.cleanupMixin()
                }
                
                it("should move the observation when it is updated") {
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    fomixin.setupMixin()
                    
                    let longAgo = Date(timeIntervalSince1970: 1)
                    let one = Observation.create(geometry: SFPoint(x: 16, andY: 21), date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                    
                    one.geometry = SFPoint(x: 20, andY: 30)

                    expect(((testimpl.mapView?.annotations[0] as? ObservationAnnotation)?.observation?.geometry as? SFPoint)?.x.intValue).toEventually(equal(20))
                    expect(testimpl.mapView?.annotations.count).toEventually(equal(1))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation
                    expect(oa?.observation).to(equal(one))
                    fomixin.cleanupMixin()
                }
                
                it("get the observation close to the location") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    let geometryone = SFPolygon(ring: SFLineString(points: [SFPoint(x: 16.1, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 21.1) as Any]))
                    let one = Observation.create(geometry: geometryone, date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    let geometrytwo = SFPolygon(ring: SFLineString(points: [SFPoint(x: 15.1, andY: 20.1) as Any, SFPoint(x: 14.9, andY: 20.1) as Any, SFPoint(x: 14.9, andY: 19.9) as Any, SFPoint(x: 15.1, andY: 19.9) as Any, SFPoint(x: 15.1, andY: 20.1) as Any]))
                    _ = Observation.create(geometry: geometrytwo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    testimpl.mapView?.delegate = testimpl
                    
                    fomixin.setupMixin()
                    
                    if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 21, longitude: 16), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                        testimpl.mapView?.setRegion(region, animated: false)
                    }
                    
                    expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(21.0000, within: 0.1))
                    expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(16.0000, within: 0.1))
                                    
                    expect(testimpl.mapView?.overlays.count).toEventually(equal(2))
                    
                    let items = fomixin.items(at: CLLocationCoordinate2D(latitude: 21, longitude: 16))
                    expect(items?.count).to(equal(1))
                    expect(items?[0]).to(beAKindOf(Observation.self))
                    expect(items?[0] as? Observation).to(equal(one))
                    
                    fomixin.cleanupMixin()
                }
                
                it("get a polygon and a polyline close to the location") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    let geometryone = SFPolygon(ring: SFLineString(points: [SFPoint(x: 16.1, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 21.1) as Any]))
                    let one = Observation.create(geometry: geometryone, date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    let geometrytwo = SFLineString(points: [SFPoint(x: 15, andY: 22) as Any, SFPoint(x: 17, andY: 20) as Any])
                    let two = Observation.create(geometry: geometrytwo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    let geometrythree = SFLineString(points: [SFPoint(x: 15, andY: 21.1) as Any, SFPoint(x: 17, andY: 21.1) as Any])
                    _ = Observation.create(geometry: geometrythree, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    testimpl.mapView?.delegate = testimpl
                    
                    fomixin.setupMixin()
                    
                    if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 21, longitude: 16), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                        testimpl.mapView?.setRegion(region, animated: false)
                    }
                    
                    expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(21.0000, within: 0.1))
                    expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(16.0000, within: 0.1))
                    
                    expect(testimpl.mapView?.overlays.count).toEventually(equal(3))
                                    
                    let items = fomixin.items(at: CLLocationCoordinate2D(latitude: 21, longitude: 16))
                    expect(items?.count).to(equal(2))
                    expect(items?[0]).to(beAKindOf(Observation.self))
                    expect(items?[0] as? Observation).to(equal(two))
                    expect(items?[1]).to(beAKindOf(Observation.self))
                    expect(items?[1] as? Observation).to(equal(one))
                    
                    fomixin.cleanupMixin()
                }
                
                it("zoom and center the map") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    let geometryone = SFPolygon(ring: SFLineString(points: [SFPoint(x: 16.1, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 21.1) as Any, SFPoint(x: 15.9, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 20.9) as Any, SFPoint(x: 16.1, andY: 21.1) as Any]))
                    let one = Observation.create(geometry: geometryone, date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    testimpl.mapView?.delegate = testimpl
                    
                    fomixin.setupMixin()
                    
                    fomixin.zoomAndCenterMap(observation: one)
                    
                    expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(21.0000, within: 0.1))
                    expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(16.0000, within: 0.1))
                    
                    fomixin.cleanupMixin()
                }
                
                it("zoom and center the map on a point") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    let geometryone = SFPoint(x: 16, andY: 21)
                    let one = Observation.create(geometry: geometryone, date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    testimpl.mapView?.delegate = testimpl
                    
                    fomixin.setupMixin()
                    
                    fomixin.zoomAndCenterMap(observation: one)
                    
                    expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(21.0000, within: 0.1))
                    expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(16.0000, within: 0.1))
                    
                    expect(testimpl.mapView?.annotations.count).to(equal(1))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    if let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation {
                        expect(oa.view).toEventually(beAKindOf(ObservationAnnotationView.self))
                        if let oav = oa.view as? ObservationAnnotationView {
                            expect(oav.isEnabled).to(beFalse())
                            expect(oav.canShowCallout).to(beFalse())
                            expect(oav.accessibilityLabel).to(equal("Observation Annotation \(one.objectID.uriRepresentation().absoluteString)"))
                            expect(oav.centerOffset).to(equal(CGPoint(x: 0, y: -((oav.image?.size.height ?? 0.0) / 2.0))))
                        }
                    }
                    
                    fomixin.cleanupMixin()
                }
                
                it("focus on an annotation then clear focus") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    let geometryone = SFPoint(x: 16, andY: 21)
                    let one = Observation.create(geometry: geometryone, date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    UserDefaults.standard.observationTimeFilterKey = .all

                    testimpl.mapView?.delegate = testimpl

                    fomixin.setupMixin()

                    fomixin.zoomAndCenterMap(observation: one)

                    expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(21.0000, within: 0.1))
                    expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(16.0000, within: 0.1))

                    expect(testimpl.mapView?.annotations.count).to(equal(1))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    var originalHeight = 0.0
                    if let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation {
                        expect(oa.view).toEventually(beAKindOf(ObservationAnnotationView.self))
                        if let oav = oa.view as? ObservationAnnotationView {
                            originalHeight = oav.frame.size.height
                            expect(oav.isEnabled).to(beFalse())
                            expect(oav.canShowCallout).to(beFalse())
                            expect(oav.accessibilityLabel).to(equal("Observation Annotation \(one.objectID.uriRepresentation().absoluteString)"))
                            expect(oav.centerOffset).to(equal(CGPoint(x: 0, y: -((oav.image?.size.height ?? 0.0) / 2.0))))
                        }
                        let notification = MapAnnotationFocusedNotification(annotation: oa, mapView: testimpl.mapView)
                        NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                    }

                    expect(testimpl.mapView?.annotations.count).to(equal(1))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    if let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation {
                        expect(oa.view).to(beAKindOf(ObservationAnnotationView.self))
                        if let oav = oa.view as? ObservationAnnotationView {
                            expect(oav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                            expect(fomixin.enlargedObservationView).to(equal(oav))
                        }
                    }
                    
                    NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
                    expect(fomixin.enlargedObservationView).toEventually(beNil())
                    if let oa = testimpl.mapView?.annotations[0] as? ObservationAnnotation {
                        expect(oa.view).to(beAKindOf(ObservationAnnotationView.self))
                        if let oav = oa.view as? ObservationAnnotationView {
                            expect(oav.frame.size.height).toEventually(equal(originalHeight))
                        }
                    }
                    
                    fomixin.cleanupMixin()
                }
                
                it("focus on an annotation then change focus to another one") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    let geometryone = SFPoint(x: 16, andY: 21)
                    let one = Observation.create(geometry: geometryone, date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    let geometrytwo = SFPoint(x: 15, andY: 20)
                    let two = Observation.create(geometry: geometrytwo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    testimpl.mapView?.delegate = testimpl
                    
                    fomixin.setupMixin()
                    
                    if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 20.5, longitude: 15.5), latitudinalMeters: 1000000, longitudinalMeters: 100000)) {
                        testimpl.mapView?.setRegion(region, animated: false)
                    }
                    
                    expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(20.5000, within: 0.5))
                    expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(15.5000, within: 0.5))
                    
                    expect(testimpl.mapView?.annotations.count).to(equal(2))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    var originalHeight = 0.0
                    guard let annotations = testimpl.mapView?.annotations else {
                        tester().fail()
                        return
                    }
                    for annotation in annotations {
                        guard let oa = annotation as? ObservationAnnotation else {
                            tester().fail()
                            return
                        }
                        expect(oa).to(beAKindOf(ObservationAnnotation.self))
                        
                        if oa.observation == one {
                            expect(oa.view).toEventually(beAKindOf(ObservationAnnotationView.self))
                            if let oav = oa.view as? ObservationAnnotationView {
                                // focus on one first
                                
                                originalHeight = oav.frame.size.height
                                expect(oav.isEnabled).to(beFalse())
                                expect(oav.canShowCallout).to(beFalse())
                                expect(oav.accessibilityLabel).to(equal("Observation Annotation \(one.objectID.uriRepresentation().absoluteString)"))
                                expect(oav.centerOffset).to(equal(CGPoint(x: 0, y: -((oav.image?.size.height ?? 0.0) / 2.0))))
                            
                                let notification = MapAnnotationFocusedNotification(annotation: oa, mapView: testimpl.mapView)
                                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                                
                                expect(oav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                                expect(fomixin.enlargedObservationView).to(equal(oav))
                            }
                        }
                    }

                    guard let annotations = testimpl.mapView?.annotations else {
                        tester().fail()
                        return
                    }
                    for annotation in annotations {
                        guard let oa = annotation as? ObservationAnnotation else {
                            tester().fail()
                            return
                        }
                        expect(oa).to(beAKindOf(ObservationAnnotation.self))
                        if oa.observation == two {
                            expect(oa.view).toEventually(beAKindOf(ObservationAnnotationView.self))
                            if let oav = oa.view as? ObservationAnnotationView {
                                // focus on one first
                                
                                originalHeight = oav.frame.size.height
                                expect(oav.isEnabled).to(beFalse())
                                expect(oav.canShowCallout).to(beFalse())
                                expect(oav.accessibilityLabel).to(equal("Observation Annotation \(two.objectID.uriRepresentation().absoluteString)"))
                                expect(oav.centerOffset).to(equal(CGPoint(x: 0, y: -((oav.image?.size.height ?? 0.0) / 2.0))))
                            
                                let notification = MapAnnotationFocusedNotification(annotation: oa, mapView: testimpl.mapView)
                                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                                expect(oav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                                expect(fomixin.enlargedObservationView).to(equal(oav))
                            }
                        }
                    }
                    
                    guard let annotations = testimpl.mapView?.annotations else {
                        tester().fail()
                        return
                    }
                    for annotation in annotations {
                        guard let oa = annotation as? ObservationAnnotation else {
                            tester().fail()
                            return
                        }
                        expect(oa).to(beAKindOf(ObservationAnnotation.self))
                        
                        if oa.observation == one {
                            expect(oa.view).to(beAKindOf(ObservationAnnotationView.self))
                            if let oav = oa.view as? ObservationAnnotationView {
                                // focus on one first
                                
                                originalHeight = oav.frame.size.height
                                expect(oav.isEnabled).to(beFalse())
                                expect(oav.canShowCallout).to(beFalse())
                                expect(oav.accessibilityLabel).to(equal("Observation Annotation \(one.objectID.uriRepresentation().absoluteString)"))
                                expect(oav.centerOffset).to(equal(CGPoint(x: 0, y: -((oav.image?.size.height ?? 0.0) / 2.0))))
                                
                                expect(oav.frame.size.height).to(equal(originalHeight))
                                expect(fomixin.enlargedObservationView).toNot(equal(oav))
                            }
                        }
                    }
                    
                    fomixin.cleanupMixin()
                }
                
                it("focus on an annotation then refocus and ensure the size stays the same") {
                    let longAgo = Date(timeIntervalSince1970: 1)
                    let geometryone = SFPoint(x: 16, andY: 21)
                    let one = Observation.create(geometry: geometryone, date: longAgo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    
                    let geometrytwo = SFPoint(x: 15, andY: 20)
                    _ = Observation.create(geometry: geometrytwo, accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
                    UserDefaults.standard.observationTimeFilterKey = .all
                    
                    testimpl.mapView?.delegate = testimpl
                    
                    fomixin.setupMixin()
                    
                    if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 20.5, longitude: 15.5), latitudinalMeters: 1000000, longitudinalMeters: 100000)) {
                        testimpl.mapView?.setRegion(region, animated: false)
                    }
                    
                    expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(20.5000, within: 0.5))
                    expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(15.5000, within: 0.5))
                    
                    expect(testimpl.mapView?.annotations.count).to(equal(2))
                    expect(testimpl.mapView?.annotations[0]).to(beAKindOf(ObservationAnnotation.self))
                    var originalHeight = 0.0
                    guard let annotations = testimpl.mapView?.annotations else {
                        tester().fail()
                        return
                    }
                    for annotation in annotations {
                        guard let oa = annotation as? ObservationAnnotation else {
                            tester().fail()
                            return
                        }
                        expect(oa).to(beAKindOf(ObservationAnnotation.self))
                        
                        if oa.observation == one {
                            expect(oa.view).toEventually(beAKindOf(ObservationAnnotationView.self))
                            if let oav = oa.view as? ObservationAnnotationView {
                                // focus on one first
                                
                                originalHeight = oav.frame.size.height
                                expect(oav.isEnabled).to(beFalse())
                                expect(oav.canShowCallout).to(beFalse())
                                expect(oav.accessibilityLabel).to(equal("Observation Annotation \(one.objectID.uriRepresentation().absoluteString)"))
                                expect(oav.centerOffset).to(equal(CGPoint(x: 0, y: -((oav.image?.size.height ?? 0.0) / 2.0))))
                                
                                let notification = MapAnnotationFocusedNotification(annotation: oa, mapView: testimpl.mapView)
                                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                                
                                expect(oav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                                expect(fomixin.enlargedObservationView).to(equal(oav))
                            }
                        }
                    }
                    
                    for annotation in annotations {
                        guard let oa = annotation as? ObservationAnnotation else {
                            tester().fail()
                            return
                        }
                        expect(oa).to(beAKindOf(ObservationAnnotation.self))
                        
                        if oa.observation == one {
                            expect(oa.view).toEventually(beAKindOf(ObservationAnnotationView.self))
                            if let oav = oa.view as? ObservationAnnotationView {
                                // focus on one again
                                expect(oav.isEnabled).to(beFalse())
                                expect(oav.canShowCallout).to(beFalse())
                                expect(oav.accessibilityLabel).to(equal("Observation Annotation \(one.objectID.uriRepresentation().absoluteString)"))
                                expect(oav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                                expect(oav.centerOffset).to(equal(CGPoint(x: 0, y: -((oav.image?.size.height ?? 0.0)))))
                                
                                let notification = MapAnnotationFocusedNotification(annotation: oa, mapView: testimpl.mapView)
                                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                                
                                expect(oav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                                expect(fomixin.enlargedObservationView).to(equal(oav))
                            }
                        }
                    }
                    
                    fomixin.cleanupMixin()
                }
            }
        }
    }
}

@MainActor
final class FilteredObservationsOverlayIdentityTests: XCTestCase {
    private var navController: UINavigationController!
    private var window: UIWindow!
    private var controller: UIViewController!
    private var mapTestImpl: FilteredObservationsMapTestImpl!
    private var filteredObservationsMapMixin: FilteredObservationsMapMixin!
    private var didSetupMixin = false

    override func setUpWithError() throws {
        try super.setUpWithError()

        TestHelpers.clearAndSetUpStack()
        window = TestHelpers.getKeyWindowVisible()
        UserDefaults.standard.mapType = 0
        UserDefaults.standard.themeOverride = 0
        UserDefaults.standard.locationDisplay = .latlng
        UserDefaults.standard.baseServerUrl = "https://magetest"

        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
        MageCoreDataFixtures.addUser(userId: "userabc")
        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
        Server.setCurrentEventId(1)
        UserDefaults.standard.currentUserId = "userabc"

        controller = UIViewController()
        let mapView = MKMapView()
        controller.view = mapView

        mapTestImpl = FilteredObservationsMapTestImpl()
        mapTestImpl.mapView = mapView
        mapTestImpl.scheme = MAGEScheme.scheme()

        filteredObservationsMapMixin = FilteredObservationsMapMixin(filteredObservationsMap: mapTestImpl)
        mapTestImpl.filteredObservationsMapMixin = filteredObservationsMapMixin

        navController = UINavigationController(rootViewController: controller)
        window.rootViewController = navController
        window.overrideUserInterfaceStyle = .unspecified
        didSetupMixin = false
    }

    override func tearDownWithError() throws {
        if didSetupMixin {
            filteredObservationsMapMixin?.cleanupMixin()
        }
        filteredObservationsMapMixin = nil
        mapTestImpl = nil
        controller?.view.subviews.forEach { $0.removeFromSuperview() }
        controller = nil
        navController = nil
        window?.resignKey()
        window?.rootViewController = nil
        window = nil
        UserDefaults.standard.themeOverride = 0
        TestHelpers.clearAndSetUpStack()
        HTTPStubs.removeAllStubs()
        try super.tearDownWithError()
    }

    private func polygonGeometry(centerLongitude: Double, centerLatitude: Double, delta: Double = 0.1) -> SFPolygon {
        return SFPolygon(ring: SFLineString(points: [
            SFPoint(xValue: centerLongitude + delta, andYValue: centerLatitude + delta) as Any,
            SFPoint(xValue: centerLongitude - delta, andYValue: centerLatitude + delta) as Any,
            SFPoint(xValue: centerLongitude - delta, andYValue: centerLatitude - delta) as Any,
            SFPoint(xValue: centerLongitude + delta, andYValue: centerLatitude - delta) as Any,
            SFPoint(xValue: centerLongitude + delta, andYValue: centerLatitude + delta) as Any
        ]))
    }

    private func polylineGeometry(startLongitude: Double, startLatitude: Double, endLongitude: Double, endLatitude: Double) -> SFLineString {
        return SFLineString(points: [
            SFPoint(xValue: startLongitude, andYValue: startLatitude) as Any,
            SFPoint(xValue: endLongitude, andYValue: endLatitude) as Any
        ])
    }

    private func overlayCount<T>(of type: T.Type) -> Int {
        return mapTestImpl.mapView?.overlays.filter { $0 is T }.count ?? 0
    }

    func testLocalPolygonRedrawKeepsSingleOverlay() {
        let observation = Observation.create(geometry: polygonGeometry(centerLongitude: 16, centerLatitude: 21), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())

        filteredObservationsMapMixin.updateObservation(observation: observation)
        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(1))

        observation.geometry = polygonGeometry(centerLongitude: 17, centerLatitude: 22)
        filteredObservationsMapMixin.updateObservation(observation: observation)

        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(1))
    }

    func testDeletingOneLocalPolygonKeepsOtherPolygonVisible() {
        let first = Observation.create(geometry: polygonGeometry(centerLongitude: 16, centerLatitude: 21), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())
        let second = Observation.create(geometry: polygonGeometry(centerLongitude: 18, centerLatitude: 23), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())

        filteredObservationsMapMixin.updateObservation(observation: first)
        filteredObservationsMapMixin.updateObservation(observation: second)
        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(2))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(2))

        filteredObservationsMapMixin.deleteObservation(observation: first)

        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(1))
        XCTAssertEqual(filteredObservationsMapMixin.polygonObservations.first?.observation, second)
    }

    func testDeletingLocalPolygonClearsBookkeeping() {
        let observation = Observation.create(geometry: polygonGeometry(centerLongitude: 16, centerLatitude: 21), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())

        filteredObservationsMapMixin.updateObservation(observation: observation)
        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(1))

        filteredObservationsMapMixin.deleteObservation(observation: observation)

        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(0))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(0))
    }

    func testLocalPolygonRemoteIdTransitionKeepsSingleOverlay() {
        let observation = Observation.create(geometry: polygonGeometry(centerLongitude: 16, centerLatitude: 21), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())

        filteredObservationsMapMixin.updateObservation(observation: observation)
        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(1))

        observation.remoteId = "polygon-remote-id"
        filteredObservationsMapMixin.updateObservation(observation: observation)

        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(1))

        filteredObservationsMapMixin.deleteObservation(observation: observation)
        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(0))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(0))
    }

    func testFetchedPolygonRedrawsDoNotAccumulateOverlays() {
        let observation = Observation.create(geometry: polygonGeometry(centerLongitude: 16, centerLatitude: 21), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())
        observation.remoteId = "server-polygon"
        UserDefaults.standard.observationTimeFilterKey = .all

        filteredObservationsMapMixin.setupMixin()
        didSetupMixin = true
        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(1))

        filteredObservationsMapMixin.addFilteredObservations()
        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(1))

        filteredObservationsMapMixin.addFilteredObservations()
        expect(self.overlayCount(of: StyledPolygon.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.polygonObservations.count).toEventually(equal(1))
    }

    func testLocalPolylineRedrawKeepsSingleOverlay() {
        let observation = Observation.create(geometry: polylineGeometry(startLongitude: 16, startLatitude: 21, endLongitude: 17, endLatitude: 22), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())

        filteredObservationsMapMixin.updateObservation(observation: observation)
        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(1))

        observation.geometry = polylineGeometry(startLongitude: 18, startLatitude: 23, endLongitude: 19, endLatitude: 24)
        filteredObservationsMapMixin.updateObservation(observation: observation)

        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(1))
    }

    func testDeletingOneLocalPolylineKeepsOtherPolylineVisible() {
        let first = Observation.create(geometry: polylineGeometry(startLongitude: 16, startLatitude: 21, endLongitude: 17, endLatitude: 22), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())
        let second = Observation.create(geometry: polylineGeometry(startLongitude: 18, startLatitude: 23, endLongitude: 19, endLatitude: 24), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())

        filteredObservationsMapMixin.updateObservation(observation: first)
        filteredObservationsMapMixin.updateObservation(observation: second)
        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(2))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(2))

        filteredObservationsMapMixin.deleteObservation(observation: first)

        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(1))
        XCTAssertEqual(filteredObservationsMapMixin.lineObservations.first?.observation, second)
    }

    func testDeletingLocalPolylineClearsBookkeeping() {
        let observation = Observation.create(geometry: polylineGeometry(startLongitude: 16, startLatitude: 21, endLongitude: 17, endLatitude: 22), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())

        filteredObservationsMapMixin.updateObservation(observation: observation)
        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(1))

        filteredObservationsMapMixin.deleteObservation(observation: observation)

        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(0))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(0))
    }

    func testLocalPolylineRemoteIdTransitionKeepsSingleOverlay() {
        let observation = Observation.create(geometry: polylineGeometry(startLongitude: 16, startLatitude: 21, endLongitude: 17, endLatitude: 22), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())

        filteredObservationsMapMixin.updateObservation(observation: observation)
        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(1))

        observation.remoteId = "polyline-remote-id"
        filteredObservationsMapMixin.updateObservation(observation: observation)

        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(1))

        filteredObservationsMapMixin.deleteObservation(observation: observation)
        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(0))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(0))
    }

    func testFetchedPolylineRedrawsDoNotAccumulateOverlays() {
        let observation = Observation.create(geometry: polylineGeometry(startLongitude: 16, startLatitude: 21, endLongitude: 17, endLatitude: 22), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default())
        observation.remoteId = "server-polyline"
        UserDefaults.standard.observationTimeFilterKey = .all

        filteredObservationsMapMixin.setupMixin()
        didSetupMixin = true
        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(1))

        filteredObservationsMapMixin.addFilteredObservations()
        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(1))

        filteredObservationsMapMixin.addFilteredObservations()
        expect(self.overlayCount(of: StyledPolyline.self)).toEventually(equal(1))
        expect(self.filteredObservationsMapMixin.lineObservations.count).toEventually(equal(1))
    }
}
