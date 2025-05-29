//
//  CanCreateObservationTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/10/22.
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

class CanCreateObservationTestImpl : NSObject, CanCreateObservation {
    var navigationController: UINavigationController?
    
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?

    var canCreateObservationMixin: CanCreateObservationMixin?
}

class CanCreateObservationTests: AsyncMageCoreDataTestCase {
    
    override open func setUp() {
        super.setUp()
    }
    
    override open func tearDown() {
        super.tearDown()
    }
    
    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    var testimpl: CanCreateObservationTestImpl!
    var mixin: CanCreateObservationMixin!
    let locationService = MockLocationService()
    
    lazy var mapStack: UIStackView = {
        let mapStack = UIStackView.newAutoLayout()
        mapStack.axis = .vertical
        mapStack.alignment = .fill
        mapStack.spacing = 0
        mapStack.distribution = .fill
        return mapStack
    }()
    
    override func setUp() async throws {
        try await super.setUp()
        await setUpViews()
        UserDefaults.standard.mapType = 0;
        UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
        
        UserDefaults.standard.baseServerUrl = "https://magetest";
        
        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
        MageCoreDataFixtures.addUser(userId: "userabc")
        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
        UserDefaults.standard.currentUserId = "userabc";

        Server.setCurrentEventId(1);
    }
    
    @MainActor
    func setUpViews() {
        if (navController != nil) {
            navController.dismiss(animated: false);
        }
        if (view != nil) {
            for subview in view.subviews {
                subview.removeFromSuperview();
            }
        }
        window = TestHelpers.getKeyWindowVisible();
        
        let mapView = MKMapView()
        
        controller = UIViewController()
        controller.view.addSubview(mapView)
        mapView.autoPinEdgesToSuperviewEdges()

        controller.view.addSubview(mapStack)
        mapStack.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        
        testimpl = CanCreateObservationTestImpl()
        testimpl.mapView = mapView
        testimpl.scheme = MAGEScheme.scheme()
        
        navController = UINavigationController(rootViewController: controller);
        testimpl.navigationController = navController
        mixin = CanCreateObservationMixin(canCreateObservation: testimpl, rootView: mapView, mapStackView: mapStack, locationService: locationService)
        
        window.rootViewController = navController;
        
        view = window
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        await tearDownViews()
        mixin = nil
        testimpl = nil
        
        UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
    }
    
    @MainActor
    func tearDownViews() {
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
        controller.dismiss(animated: false);
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .unspecified
        }
        window?.resignKey();
        window.rootViewController = nil;
        navController = nil;
        view = nil;
        window = nil;
    }
    
    @MainActor
    func testInitializeTheCanCreateObservationAndPushTheNewButton() {
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

        tester().waitForView(withAccessibilityLabel: "New")
        tester().tapView(withAccessibilityLabel: "New")
        tester().waitForView(withAccessibilityLabel: "ObservationEditCardCollection")
        tester().tapView(withAccessibilityLabel: "CANCEL")
        
        let geometryView = viewTester().usingLabel("geometry value").view as! MDCFilledTextField
        expect(geometryView.text).to(equal("40.0085, -105.2678 GPS ± 6.00m"))
        
        expect(self.mixin.editCoordinator).toNot(beNil())
        tester().tapView(withAccessibilityLabel: "Save")
        
        expect(self.mixin.editCoordinator).to(beNil())

        mixin.cleanupMixin()
    }
    
    @MainActor
    func testInitializeTheCanCreateObservationAndLongPressTheMap() {
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
        
        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:15, longitude:25), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
            mixin.mapView?.setRegion(region, animated: false)
        }
        mixin.mapView!.accessibilityLabel = "map"
        viewTester().usingLabel("map").longPress()
        
        tester().waitForView(withAccessibilityLabel: "ObservationEditCardCollection")
        tester().tapView(withAccessibilityLabel: "CANCEL")
        
        let geometryView = viewTester().usingLabel("geometry value").view as! MDCFilledTextField
        expect(geometryView.text).to(equal("15.0365, 25.0000 "))
        
        expect(self.mixin.editCoordinator).toNot(beNil())
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForTappableView(withAccessibilityLabel: "Yes, Discard")
        tester().tapView(withAccessibilityLabel: "Yes, Discard")
        
        expect(self.mixin.editCoordinator).to(beNil())
                        
        mixin.cleanupMixin()
    }
}
