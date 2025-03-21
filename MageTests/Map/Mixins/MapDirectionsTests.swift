//
//  MapDirectionsTests.swift
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

@testable @preconcurrency import MAGE
import CoreLocation
import MapKit

class MapDirectionsTestImpl : NSObject, MapDirections {
    var mapView: MKMapView?
    
    var mapDirectionsMixin: MapDirectionsMixin?
}

extension MapDirectionsTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return mapDirectionsMixin?.renderer(overlay: overlay) ?? mapDirectionsMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return mapDirectionsMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class MapDirectionsTests: AsyncMageCoreDataTestCase {
    
    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    var testimpl: MapDirectionsTestImpl!
    var mixin: MapDirectionsMixin!
    
    var mapStack: UIStackView!
    var mockCLLocationManager: MockCLLocationManager!
    
    @MainActor
    override func setUp() async throws {
        if (navController != nil) {
            navController.dismiss(animated: false);
        }
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
        
        testimpl = MapDirectionsTestImpl()
        testimpl.mapView = mapView
        mapView.delegate = testimpl
        
        mockCLLocationManager = MockCLLocationManager()
        mixin = MapDirectionsMixin(mapDirections: testimpl, viewController: controller, mapStack: mapStack, scheme: MAGEScheme.scheme(), locationManager: mockCLLocationManager, sourceView: nil)
        testimpl.mapDirectionsMixin = mixin
        
        navController = UINavigationController(rootViewController: controller);
        
        window.rootViewController = navController;
        
        view = window
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    @MainActor
    override func tearDown() async throws {
        mixin = nil
        testimpl = nil
        
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
        controller.dismiss(animated: false);
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
    
//    @MainActor
//    func testGetDirectionsToAnAObservation() {
//        let observation = Observation.create(geometry: SFPoint(x: -105, andY: 40.01), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
//        
//        let mapState = MapState()
//        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mockCLLocationManager.mockedLocation!.coordinate.latitude, longitude: mockCLLocationManager.mockedLocation!.coordinate.longitude), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
//            mixin.mapView?.setRegion(region, animated: false)
//        }
//        
//        let notification = DirectionsToItemNotification(itemKey: observation.objectID.uriRepresentation().absoluteString, dataSource: DataSources.observation, includeCopy: false)
//        NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
//        
//        tester().waitForView(withAccessibilityLabel: "Navigate With...")
//        tester().waitForView(withAccessibilityLabel: "Apple Maps")
//        tester().waitForView(withAccessibilityLabel: "Google Maps")
//        tester().waitForView(withAccessibilityLabel: "Bearing")
//        
//        var mapRequestFocusObserverCalled = false
//        let mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beNil())
//            mapRequestFocusObserverCalled = true
//        }
//        
//        var startStraightLineNavigationObserverCalled = false
//        let startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beAKindOf(StraightLineNavigationNotification.self))
//            let notification = notification.object as! StraightLineNavigationNotification
//            expect(notification.image).toNot(beNil())
//            expect(notification.title).to(equal("Observation"))
////                    expect(notification.itemKey).to(equal(observation.objectID.uriRepresentation().absoluteString))
////                    expect(notification.observation).to(equal(observation))
////                    expect(notification.user).to(beNil())
////                    expect(notification.feedItem).to(beNil())
//            expect(notification.coordinate.latitude).to(equal(observation.location?.coordinate.latitude))
//            expect(notification.coordinate.longitude).to(equal(observation.location?.coordinate.longitude))
//
//            startStraightLineNavigationObserverCalled = true
//        }
//        
//        tester().tapView(withAccessibilityLabel: "Bearing")
//        expect(mapRequestFocusObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(mapRequestFocusObserver, name: .MapRequestFocus, object: nil)
//        expect(startStraightLineNavigationObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(2))
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.009))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.13385))
//            }
//        }
//        
//        observation.geometry = SFPoint(x: -105.1, andY: 40.1)
//        tester().wait(forTimeInterval: 1)
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.05401))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.183849))
//            }
//        }
//        
//        tester().waitForView(withAccessibilityLabel: "cancel")
//        tester().tapView(withAccessibilityLabel: "cancel")
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(0))
//
//        mixin.cleanupMixin()
//    }
//    
//    @MainActor
//    func testGetDirectionsToARemoteObservation() {
//        let observation = Observation.create(geometry: SFPoint(x: -105, andY: 40.01), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
//        observation.remoteId = "observationabc"
//        
//        let mapState = MapState()
//        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mockCLLocationManager.mockedLocation!.coordinate.latitude, longitude: mockCLLocationManager.mockedLocation!.coordinate.longitude), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
//            mixin.mapView?.setRegion(region, animated: false)
//        }
//        
//        let notification = DirectionsToItemNotification(itemKey: observation.objectID.uriRepresentation().absoluteString, dataSource: DataSources.observation, includeCopy: false)
//        NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
//        
//        tester().waitForView(withAccessibilityLabel: "Navigate With...")
//        tester().waitForView(withAccessibilityLabel: "Apple Maps")
//        tester().waitForView(withAccessibilityLabel: "Google Maps")
//        tester().waitForView(withAccessibilityLabel: "Bearing")
//        
//        var mapRequestFocusObserverCalled = false
//        let mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beNil())
//            mapRequestFocusObserverCalled = true
//        }
//        
//        var startStraightLineNavigationObserverCalled = false
//        let startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beAKindOf(StraightLineNavigationNotification.self))
//            let notification = notification.object as! StraightLineNavigationNotification
//            expect(notification.image).toNot(beNil())
//            expect(notification.title).to(equal("Observation"))
////                    expect(notification.observation).to(equal(observation))
////                    expect(notification.user).to(beNil())
////                    expect(notification.feedItem).to(beNil())
//            expect(notification.coordinate.latitude).to(equal(observation.location?.coordinate.latitude))
//            expect(notification.coordinate.longitude).to(equal(observation.location?.coordinate.longitude))
//            
//            startStraightLineNavigationObserverCalled = true
//        }
//        
//        tester().tapView(withAccessibilityLabel: "Bearing")
//        expect(mapRequestFocusObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(mapRequestFocusObserver, name: .MapRequestFocus, object: nil)
//        expect(startStraightLineNavigationObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(2))
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.009))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.13385))
//            }
//        }
//        
//        observation.geometry = SFPoint(x: -105.1, andY: 40.1)
//        tester().wait(forTimeInterval: 1)
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.05401))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.183849))
//            }
//        }
//        
//        tester().waitForView(withAccessibilityLabel: "cancel")
//        tester().tapView(withAccessibilityLabel: "cancel")
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(0))
//                        
//        mixin.cleanupMixin()
//    }
//    
//    func testGetDirectionsToARemoteObservationUpdateMyLocation() {
//        let observation = Observation.create(geometry: SFPoint(x: -105, andY: 40.01), accuracy: 4.5, provider: "gps", delta: 2, context: NSManagedObjectContext.mr_default());
//        observation.remoteId = "observationabc"
//        
//        let mapState = MapState()
//        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mockCLLocationManager.mockedLocation!.coordinate.latitude, longitude: mockCLLocationManager.mockedLocation!.coordinate.longitude), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
//            mixin.mapView?.setRegion(region, animated: false)
//        }
//        
//        let notification = DirectionsToItemNotification(itemKey: observation.objectID.uriRepresentation().absoluteString, dataSource: DataSources.observation, includeCopy: false)
//        NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
//        
//        tester().waitForView(withAccessibilityLabel: "Navigate With...")
//        tester().waitForView(withAccessibilityLabel: "Apple Maps")
//        tester().waitForView(withAccessibilityLabel: "Google Maps")
//        tester().waitForView(withAccessibilityLabel: "Bearing")
//        
//        var mapRequestFocusObserverCalled = false
//        let mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beNil())
//            mapRequestFocusObserverCalled = true
//        }
//        
//        var startStraightLineNavigationObserverCalled = false
//        let startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beAKindOf(StraightLineNavigationNotification.self))
//            let notification = notification.object as! StraightLineNavigationNotification
//            expect(notification.image).toNot(beNil())
//            expect(notification.title).to(equal("Observation"))
////                    expect(notification.observation).to(equal(observation))
////                    expect(notification.user).to(beNil())
////                    expect(notification.feedItem).to(beNil())
//            expect(notification.coordinate.latitude).to(equal(observation.location?.coordinate.latitude))
//            expect(notification.coordinate.longitude).to(equal(observation.location?.coordinate.longitude))
//            
//            startStraightLineNavigationObserverCalled = true
//        }
//        
//        tester().tapView(withAccessibilityLabel: "Bearing")
//        expect(mapRequestFocusObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(mapRequestFocusObserver, name: .MapRequestFocus, object: nil)
//        expect(startStraightLineNavigationObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(2))
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.009))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.13385))
//            }
//        }
//                        
//        mockCLLocationManager.updateMockedLocation(location: CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.3, longitude: -105.3), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, course: 200, courseAccuracy: 12.0, speed: 254.0, speedAccuracy: 15.0, timestamp: Date()))
//        
//        tester().wait(forTimeInterval: 1)
//        
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.1552))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.15))
//            }
//        }
//        
//        tester().waitForView(withAccessibilityLabel: "cancel")
//        tester().tapView(withAccessibilityLabel: "cancel")
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(0))
//        
//        mixin.cleanupMixin()
//    }
//    
//    @MainActor
//    func testGetDirectionsToAUser() {
//        var user = MageCoreDataFixtures.addUser(userId: "userabc")
//        MageCoreDataFixtures.addLocation(userId: "userabc", geometry: SFPoint(x: -105, andY: 40.01))
//        user = User.mr_findFirst(byAttribute: "remoteId", withValue: "userabc")
//
//        let mapState = MapState()
//        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mockCLLocationManager.mockedLocation!.coordinate.latitude, longitude: mockCLLocationManager.mockedLocation!.coordinate.longitude), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
//            mixin.mapView?.setRegion(region, animated: false)
//        }
//        
//        let notification = DirectionsToItemNotification(itemKey: user?.objectID.uriRepresentation().absoluteString, dataSource: DataSources.user, includeCopy: false)
//        NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
//        
//        tester().waitForView(withAccessibilityLabel: "Navigate With...")
//        tester().waitForView(withAccessibilityLabel: "Apple Maps")
//        tester().waitForView(withAccessibilityLabel: "Google Maps")
//        tester().waitForView(withAccessibilityLabel: "Bearing")
//        
//        var mapRequestFocusObserverCalled = false
//        let mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beNil())
//            mapRequestFocusObserverCalled = true
//        }
//        
//        var startStraightLineNavigationObserverCalled = false
//        let startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beAKindOf(StraightLineNavigationNotification.self))
//            let notification = notification.object as! StraightLineNavigationNotification
//            expect(notification.image).toNot(beNil())
//            expect(notification.title).to(equal("User ABC"))
////                    expect(notification.user).to(equal(user))
////                    expect(notification.observation).to(beNil())
////                    expect(notification.feedItem).to(beNil())
//            expect(notification.coordinate.latitude).to(equal(user?.location?.coordinate.latitude))
//            expect(notification.coordinate.longitude).to(equal(user?.location?.coordinate.longitude))
//            
//            startStraightLineNavigationObserverCalled = true
//        }
//        
//        tester().tapView(withAccessibilityLabel: "Bearing")
//        expect(mapRequestFocusObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(mapRequestFocusObserver, name: .MapRequestFocus, object: nil)
//        expect(startStraightLineNavigationObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(2))
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.009))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.13385))
//            }
//        }
//        
//        MageCoreDataFixtures.addLocation(userId: "userabc", geometry: SFPoint(x: -105.1, andY: 40.1))
//
//        tester().wait(forTimeInterval: 1)
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.05401))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.183849))
//            }
//        }
//        
//        tester().waitForView(withAccessibilityLabel: "cancel")
//        tester().tapView(withAccessibilityLabel: "cancel")
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(0))
//        
//        mixin.cleanupMixin()
//    }
//    
//    @MainActor
//    func testGetDirectionsToAUserChangeMyLocations() {
//        var user = MageCoreDataFixtures.addUser(userId: "userabc")
//        MageCoreDataFixtures.addLocation(userId: "userabc", geometry: SFPoint(x: -105, andY: 40.01))
//        user = User.mr_findFirst(byAttribute: "remoteId", withValue: "userabc")
//        
//        let mapState = MapState()
//        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mockCLLocationManager.mockedLocation!.coordinate.latitude, longitude: mockCLLocationManager.mockedLocation!.coordinate.longitude), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
//            mixin.mapView?.setRegion(region, animated: false)
//        }
//        
//        let notification = DirectionsToItemNotification(itemKey: user?.objectID.uriRepresentation().absoluteString, dataSource: DataSources.user, includeCopy: false)
//        NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
//        
//        tester().waitForView(withAccessibilityLabel: "Navigate With...")
//        tester().waitForView(withAccessibilityLabel: "Apple Maps")
//        tester().waitForView(withAccessibilityLabel: "Google Maps")
//        tester().waitForView(withAccessibilityLabel: "Bearing")
//        
//        var mapRequestFocusObserverCalled = false
//        let mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beNil())
//            mapRequestFocusObserverCalled = true
//        }
//        
//        var startStraightLineNavigationObserverCalled = false
//        let startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beAKindOf(StraightLineNavigationNotification.self))
//            let notification = notification.object as! StraightLineNavigationNotification
//            expect(notification.image).toNot(beNil())
//            expect(notification.title).to(equal("User ABC"))
////                    expect(notification.user).to(equal(user))
////                    expect(notification.observation).to(beNil())
////                    expect(notification.feedItem).to(beNil())
//            expect(notification.coordinate.latitude).to(equal(user?.location?.coordinate.latitude))
//            expect(notification.coordinate.longitude).to(equal(user?.location?.coordinate.longitude))
//            
//            startStraightLineNavigationObserverCalled = true
//        }
//        
//        tester().tapView(withAccessibilityLabel: "Bearing")
//        expect(mapRequestFocusObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(mapRequestFocusObserver, name: .MapRequestFocus, object: nil)
//        expect(startStraightLineNavigationObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(2))
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.009))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.13385))
//            }
//        }
//        
//        mockCLLocationManager.updateMockedLocation(location: CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.3, longitude: -105.3), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, course: 200, courseAccuracy: 12.0, speed: 254.0, speedAccuracy: 15.0, timestamp: Date()))
//        
//        tester().wait(forTimeInterval: 1)
//        
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.1552))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.15))
//            }
//        }
//        
//        tester().waitForView(withAccessibilityLabel: "cancel")
//        tester().tapView(withAccessibilityLabel: "cancel")
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(0))
//        
//        mixin.cleanupMixin()
//    }
//    
//    @MainActor
//    func testGetDirectionsToAFeedItem() {
//        MageCoreDataFixtures.addFeedToEvent()
//        let feedItem = MageCoreDataFixtures.addFeedItemToFeed(simpleFeature: SFPoint(x: -105, andY: 40.01))
//        let mapState = MapState()
//        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mockCLLocationManager.mockedLocation!.coordinate.latitude, longitude: mockCLLocationManager.mockedLocation!.coordinate.longitude), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
//            mixin.mapView?.setRegion(region, animated: false)
//        }
//        
//        let notification = DirectionsToItemNotification(itemKey: feedItem?.objectID.uriRepresentation().absoluteString, dataSource: DataSources.feedItem, includeCopy: false)
//        NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
//        
//        tester().waitForView(withAccessibilityLabel: "Navigate With...")
//        tester().waitForView(withAccessibilityLabel: "Apple Maps")
//        tester().waitForView(withAccessibilityLabel: "Google Maps")
//        tester().waitForView(withAccessibilityLabel: "Bearing")
//        
//        var mapRequestFocusObserverCalled = false
//        let mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beNil())
//            mapRequestFocusObserverCalled = true
//        }
//        
//        var startStraightLineNavigationObserverCalled = false
//        let startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beAKindOf(StraightLineNavigationNotification.self))
//            let notification = notification.object as! StraightLineNavigationNotification
//            expect(notification.image).toNot(beNil())
//            expect(notification.title).to(equal(" "))
////                    expect(notification.user).to(beNil())
////                    expect(notification.observation).to(beNil())
////                    expect(notification.feedItem).to(equal(feedItem))
//            expect(notification.coordinate.latitude).to(equal(feedItem?.coordinate.latitude))
//            expect(notification.coordinate.longitude).to(equal(feedItem?.coordinate.longitude))
//            startStraightLineNavigationObserverCalled = true
//        }
//        
//        tester().tapView(withAccessibilityLabel: "Bearing")
//        expect(mapRequestFocusObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(mapRequestFocusObserver, name: .MapRequestFocus, object: nil)
//        expect(startStraightLineNavigationObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(2))
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.009))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.13385))
//            }
//        }
//        
//        feedItem?.simpleFeature = SFPoint(x: -105.1, andY: 40.1)
//        
//        tester().wait(forTimeInterval: 1)
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.05401))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.183849))
//            }
//        }
//        
//        tester().waitForView(withAccessibilityLabel: "cancel")
//        tester().tapView(withAccessibilityLabel: "cancel")
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(0))
//        
//        mixin.cleanupMixin()
//    }
//    
//    @MainActor
//    func testGetDirectionsToAFeedItemMoveMe() {
//        var feedIconFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/icons/iconid/content")
//        ) { (request) -> HTTPStubsResponse in
//            feedIconFetchStubCalled = true;
//            let stubPath = OHPathForFile("test_marker.png", MageTests.self);
//            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
//        }
//        
//        MageCoreDataFixtures.addFeedToEvent(mapStyle: [FeedMapStyleKey.icon.key: [FeedMapStyleKey.id.key: "iconid"]])
//        let feedItem = MageCoreDataFixtures.addFeedItemToFeed(simpleFeature: SFPoint(x: -105, andY: 40.01))
//        let mapState = MapState()
//        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mockCLLocationManager.mockedLocation!.coordinate.latitude, longitude: mockCLLocationManager.mockedLocation!.coordinate.longitude), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
//            mixin.mapView?.setRegion(region, animated: false)
//        }
//        
//        let notification = DirectionsToItemNotification(itemKey: feedItem?.objectID.uriRepresentation().absoluteString, dataSource: DataSources.feedItem, includeCopy: false)
//        NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
//        
//        tester().waitForView(withAccessibilityLabel: "Navigate With...")
//        tester().waitForView(withAccessibilityLabel: "Apple Maps")
//        tester().waitForView(withAccessibilityLabel: "Google Maps")
//        tester().waitForView(withAccessibilityLabel: "Bearing")
//        
//        var mapRequestFocusObserverCalled = false
//        let mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beNil())
//            mapRequestFocusObserverCalled = true
//        }
//        
//        var startStraightLineNavigationObserverCalled = false
//        let startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beAKindOf(StraightLineNavigationNotification.self))
//            let notification = notification.object as! StraightLineNavigationNotification
//            expect(notification.image).toNot(beNil())
//            expect(notification.title).to(equal(" "))
////                    expect(notification.user).to(beNil())
////                    expect(notification.observation).to(beNil())
////                    expect(notification.feedItem).to(equal(feedItem))
//            expect(notification.coordinate.latitude).to(equal(feedItem?.coordinate.latitude))
//            expect(notification.coordinate.longitude).to(equal(feedItem?.coordinate.longitude))
//            startStraightLineNavigationObserverCalled = true
//        }
//        
//        tester().tapView(withAccessibilityLabel: "Bearing")
//        expect(mapRequestFocusObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(mapRequestFocusObserver, name: .MapRequestFocus, object: nil)
//        expect(startStraightLineNavigationObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(2))
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.009))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.13385))
//            }
//        }
//        
//        mockCLLocationManager.updateMockedLocation(location: CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.3, longitude: -105.3), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, course: 200, courseAccuracy: 12.0, speed: 254.0, speedAccuracy: 15.0, timestamp: Date()))
//        
//        tester().wait(forTimeInterval: 1)
//        
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "relative bearing" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(40.1552))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-105.15))
//            }
//        }
//        
//        tester().waitForView(withAccessibilityLabel: "cancel")
//        tester().tapView(withAccessibilityLabel: "cancel")
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(0))
//        expect(feedIconFetchStubCalled).toEventually(beTrue())
//        
//        mixin.cleanupMixin()
//    }
//    
//    @MainActor
//    func testGetDirectionsToAFeedItemUpdateMyHeading() {
//        var feedIconFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/icons/iconid/content")
//        ) { (request) -> HTTPStubsResponse in
//            feedIconFetchStubCalled = true;
//            let stubPath = OHPathForFile("test_marker.png", MageTests.self);
//            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
//        }
//        
//        MageCoreDataFixtures.addFeedToEvent(mapStyle: [FeedMapStyleKey.icon.key: [FeedMapStyleKey.id.key: "iconid"]])
//        let feedItem = MageCoreDataFixtures.addFeedItemToFeed(simpleFeature: SFPoint(x: -105, andY: 40.01))
//        let mapState = MapState()
//        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
//        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: mockCLLocationManager.mockedLocation!.coordinate.latitude, longitude: mockCLLocationManager.mockedLocation!.coordinate.longitude), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
//            mixin.mapView?.setRegion(region, animated: false)
//        }
//        
//        let notification = DirectionsToItemNotification(itemKey: feedItem?.objectID.uriRepresentation().absoluteString, dataSource: DataSources.feedItem, includeCopy: false)
//        NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
//        
//        tester().waitForView(withAccessibilityLabel: "Navigate With...")
//        tester().waitForView(withAccessibilityLabel: "Apple Maps")
//        tester().waitForView(withAccessibilityLabel: "Google Maps")
//        tester().waitForView(withAccessibilityLabel: "Bearing")
//        
//        var mapRequestFocusObserverCalled = false
//        let mapRequestFocusObserver = NotificationCenter.default.addObserver(forName: .MapRequestFocus, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beNil())
//            mapRequestFocusObserverCalled = true
//        }
//        
//        var startStraightLineNavigationObserverCalled = false
//        let startStraightLineNavigationObserver = NotificationCenter.default.addObserver(forName: .StartStraightLineNavigation, object: nil, queue: .main) { notification in
//            expect(notification.object).to(beAKindOf(StraightLineNavigationNotification.self))
//            let notification = notification.object as! StraightLineNavigationNotification
//            expect(notification.image).toNot(beNil())
//            expect(notification.title).to(equal(" "))
////                    expect(notification.user).to(beNil())
////                    expect(notification.observation).to(beNil())
////                    expect(notification.feedItem).to(equal(feedItem))
//            expect(notification.coordinate.latitude).to(equal(feedItem?.coordinate.latitude))
//            expect(notification.coordinate.longitude).to(equal(feedItem?.coordinate.longitude))
//            startStraightLineNavigationObserverCalled = true
//        }
//        
//        // set the location to be stationary
//        mockCLLocationManager.updateMockedLocation(location: CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, course: 200, courseAccuracy: 12.0, speed: 0.0, speedAccuracy: 15.0, timestamp: Date()))
//        
//        tester().tapView(withAccessibilityLabel: "Bearing")
//        expect(mapRequestFocusObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(mapRequestFocusObserver, name: .MapRequestFocus, object: nil)
//        expect(startStraightLineNavigationObserverCalled).toEventually(beTrue())
//        NotificationCenter.default.removeObserver(startStraightLineNavigationObserver, name: .StartStraightLineNavigation, object: nil)
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(2))
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "heading" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(39.0500))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-106.7729))
//            }
//        }
//        let heading = MockCLHeading()
//        heading.mockedMagneticHeading = 100.0
//        heading.mockedTrueHeading = 101.0
//        mockCLLocationManager.updateMockedHeading(heading: heading)
//        tester().wait(forTimeInterval: 1)
//                        
//        for overlay in mixin.mapView!.overlays {
//            if let overlay = overlay as? NavigationOverlay, overlay.accessibilityLabel == "heading" {
//                expect(overlay.coordinate.latitude).to(beCloseTo(39.6876))
//                expect(overlay.coordinate.longitude).to(beCloseTo(-103.3430))
//            }
//        }
//        
//        tester().waitForView(withAccessibilityLabel: "cancel")
//        tester().tapView(withAccessibilityLabel: "cancel")
//        
//        expect(self.mixin.mapView?.overlays.count).toEventually(equal(0))
//        expect(feedIconFetchStubCalled).toEventually(beTrue())
//        
//        mixin.cleanupMixin()
//    }
}
