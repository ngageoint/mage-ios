//
//  HasMapSettingsTests.swift
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

class HasMapSettingsTestImpl : NSObject, HasMapSettings {
    var navigationController: UINavigationController?
    
    var mapView: MKMapView?
    var scheme: MDCContainerScheming?

    var hasMapSettingsMixin: HasMapSettingsMixin?
}

class HasMapSettingsTests: AsyncMageCoreDataTestCase {

    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    var testimpl: HasMapSettingsTestImpl!
    var mixin: HasMapSettingsMixin!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        if (navController != nil) {
            navController.dismiss(animated: false)
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
        
        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
        
        Server.setCurrentEventId(1);
        
        controller = UIViewController()
        let mapView = MKMapView()
        controller.view = mapView
        
        testimpl = HasMapSettingsTestImpl()
        testimpl.mapView = mapView
        testimpl.scheme = MAGEScheme.scheme()
        
        navController = UINavigationController(rootViewController: controller);
        testimpl.navigationController = navController
        mixin = HasMapSettingsMixin(hasMapSettings: testimpl, rootView: mapView)
        window.rootViewController = navController;
        
        view = window
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    @MainActor
    override func tearDown() async throws {
        try await super.tearDown()
        mixin = nil
        testimpl = nil
        
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
        controller.dismiss(animated: false);
        UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
        
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
    func testInitializeTheHasMapSettings() {
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

        tester().waitForView(withAccessibilityLabel: "map_settings")
        
        mixin.cleanupMixin()
    }
    
    @MainActor
    func testInitializeTheHasMapSettingsWithANotLoadedLayerThenLoadIt() {
        var stubCalled = false;
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers")
        ) { (request) -> HTTPStubsResponse in
            stubCalled = true;
            return HTTPStubsResponse(jsonObject: [[
                LayerKey.id.key: 1,
                LayerKey.name.key: "name",
                LayerKey.type.key: "GeoPackage",
                LayerKey.file.key: [
                    LayerFileKey.name.key:"geopackage.gpkg",
                    LayerFileKey.contentType.key: "application/octet-stream",
                    LayerFileKey.size.key: "303104"
                ]
            ]], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        Layer.refreshLayers(eventId: 1);
        
        expect(stubCalled).toEventually(beTrue());
        expect(Layer.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find layer");
        
        
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
        tester().waitForView(withAccessibilityLabel: "layer_download_circle")
        
        MagicalRecord.save(blockAndWait:{ (localContext: NSManagedObjectContext) in
            let layer = Layer.mr_findFirst()
            expect(layer).toNot(beNil())
            layer?.loaded = true
        })
        
        NotificationCenter.default.post(name: .GeoPackageImported, object: nil)
        tester().waitForAbsenceOfView(withAccessibilityLabel: "layer_download_circle")
                        
        mixin.cleanupMixin()
    }
    
    @MainActor
    func testTapTheMapSettingsButton() {
        let mapState = MapState()
        mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
        tester().waitForView(withAccessibilityLabel: "map_settings")
        tester().tapView(withAccessibilityLabel: "map_settings")
        
        expect(self.navController.topViewController).toEventually(beAnInstanceOf(MapSettings.self));
        tester().tapView(withAccessibilityLabel: "Done")
        expect(self.navController.topViewController).toEventuallyNot(beAnInstanceOf(MapSettings.self));

        mixin.cleanupMixin()
    }
    
}
