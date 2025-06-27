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
import MapFramework

@testable import MAGE
import CoreLocation
import MapKit

class BottomSheetEnabledTestImpl : NSObject, BottomSheetEnabled {
    var navigationController: UINavigationController?
    var mapView: MKMapView?
    var scheme: AppContainerScheming?
    var bottomSheetMixin: BottomSheetMixin?
}

class BottomSheetEnabledTests: AsyncMageCoreDataTestCase {
    
    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    var testimpl: BottomSheetEnabledTestImpl!
    var mixin: BottomSheetMixin!
    
    var mapStack: UIStackView!
    
    override func setUp() async throws {
        try await super.setUp()
        await setupViews()
        UserDefaults.standard.mapType = 0;
        UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
        
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.selectedOnlineLayers = nil
        UserDefaults.standard.observationTimeFilterKey = .all
        
        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
        
        Server.setCurrentEventId(1);
    }
    
    @MainActor
    func setupViews() {
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
        
        mapStack = UIStackView.newAutoLayout()
        mapStack.axis = .vertical
        mapStack.alignment = .fill
        mapStack.spacing = 0
        mapStack.distribution = .fill
        
        controller.view.addSubview(mapStack)
        mapStack.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .top)
        
        testimpl = BottomSheetEnabledTestImpl()
        testimpl.mapView = mapView
        testimpl.scheme = MAGEScheme.scheme()
        
        navController = UINavigationController(rootViewController: controller);
        testimpl.navigationController = navController
        mixin = BottomSheetMixin(bottomSheetEnabled: testimpl)
        testimpl.bottomSheetMixin = mixin
        
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
        
        UserDefaults.standard.selectedOnlineLayers = nil
        
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
    func testObservationBottomSheet() {
        let observation = MageCoreDataFixtures.addObservationToEvent()!
        let oa = ObservationAnnotation(observation: observation, geometry: observation.geometry)
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

        @Injected(\.bottomSheetRepository)
        var bottomSheetRepository: BottomSheetRepository
        
        if let location = observation.locations?.first {
            
            bottomSheetRepository.setItemKeys(itemKeys: [DataSources.observation.key: [location.objectID.uriRepresentation().absoluteString]])
        }
        
        tester().waitForView(withAccessibilityLabel: "At Venue")
        
        bottomSheetRepository.setItemKeys(itemKeys: nil)

        tester().waitForAbsenceOfView(withAccessibilityLabel: "At Venue")
        
        mixin.cleanupMixin()
    }
    
    @MainActor
    func testUserBottomSheet() {
        MageCoreDataFixtures.addUser()
        let location = MageCoreDataFixtures.addLocation()
        let ua = LocationAnnotation(location: location)
        
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
        
        @Injected(\.bottomSheetRepository)
        var bottomSheetRepository: BottomSheetRepository
        bottomSheetRepository.setItemKeys(itemKeys: [DataSources.user.key: [ua!.user.objectID.uriRepresentation().absoluteString]])

        tester().waitForView(withAccessibilityLabel: "User ABC")
        tester().tapScreen(at: CGPoint.zero)
        tester().waitForAbsenceOfView(withAccessibilityLabel: "User ABC")
        
        mixin.cleanupMixin()
    }
    
    @MainActor
    func testStaticPointBottomSheet() {
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
        
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

        @Injected(\.bottomSheetRepository)
        var bottomSheetRepository: BottomSheetRepository
        bottomSheetRepository.setItemKeys(itemKeys: [DataSources.featureItem.key: [sa.itemKey]])
        
        tester().waitForView(withAccessibilityLabel: "Point")
        expect(iconStubCalled).toEventually(beTrue())
        
        bottomSheetRepository.setItemKeys(itemKeys: nil)
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Point")
        
        mixin.cleanupMixin()
    }
}
