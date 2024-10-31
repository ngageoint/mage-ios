//
//  GeoPackageBaseMapTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/7/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs
import MagicalRecord
import MapFramework

@testable import MAGE

class GeoPackageBaseMapTestImpl : GeoPackageBaseMap {
    var mapView: MKMapView?
    
    var geoPackageBaseMapMixin: GeoPackageBaseMapMixin?
}

class GeoPackageBaseMapTests: AsyncMageCoreDataTestCase {
    
//    override func spec() {
//        
//        describe("GeoPackageBaseMapTests") {
    
    var navController: UINavigationController!
    var view: UIView!
    var window: UIWindow!;
    var controller: UIViewController!
    var gptest: GeoPackageBaseMapTestImpl!
    var gpmixin: GeoPackageBaseMapMixin!
            
    override func setUp() async throws {
        try await super.setUp()
        await setUpViews()
        UserDefaults.standard.mapType = 0;
        UserDefaults.standard.themeOverride = 0;
        UserDefaults.standard.locationDisplay = .latlng;
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
        
        controller = UIViewController()
        let mapView = MKMapView()
        controller.view = mapView
        
        gptest = GeoPackageBaseMapTestImpl()
        gptest.mapView = mapView
        
        gpmixin = GeoPackageBaseMapMixin(mapView: mapView)
        gptest.geoPackageBaseMapMixin = gpmixin
        
        navController = UINavigationController(rootViewController: controller);
        window.rootViewController = navController;
        
        view = window
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        await tearDownViews()
        UserDefaults.standard.themeOverride = 0
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
    func testInitializeTheGeoPackageBaseMapWithDarkMap() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let _ = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = 3
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .dark
        }
        tester().wait(forTimeInterval: 0.5)

        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)

        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithLightMap() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let _ = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = 3
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .light
        }
        tester().wait(forTimeInterval: 0.5)
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithoutOverriding() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = 3
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0]).to(beAKindOf(BaseMapOverlay.self))
        if UITraitCollection.current.userInterfaceStyle == .dark {
            expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
        } else {
            expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
        }
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithOverrideUnspecified() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = 3
        UserDefaults.standard.mapShowTraffic = false
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .unspecified
        }
        tester().wait(forTimeInterval: 0.5)
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0]).to(beAKindOf(BaseMapOverlay.self))
        if UITraitCollection.current.userInterfaceStyle == .dark {
            expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
        } else {
            expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
        }
        expect(self.gpmixin.mapView?.showsTraffic).to(beFalse())
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithOverrideUnspecifiedAndTrafficSetToYes() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = 3
        UserDefaults.standard.mapShowTraffic = false
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .unspecified
        }
        tester().wait(forTimeInterval: 0.5)
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0]).to(beAKindOf(BaseMapOverlay.self))
        if UITraitCollection.current.userInterfaceStyle == .dark {
            expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
        } else {
            expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
        }
        // this should still be false b/c on offline map there is no traffic
        expect(self.gpmixin.mapView?.showsTraffic).to(beFalse())
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithOnlineMap() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let _ = appDelegate.getBaseMap(),
              let _ = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = Int(MKMapType.standard.rawValue)
        UserDefaults.standard.mapShowTraffic = false
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).to(equal(0))
        expect(self.gpmixin.mapView?.mapType).to(equal(.standard))
        expect(self.gpmixin.mapView?.showsTraffic).to(beFalse())
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithOnlineMapAndTraffic() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let _ = appDelegate.getBaseMap(),
              let _ = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = Int(MKMapType.standard.rawValue)
        UserDefaults.standard.mapShowTraffic = true
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).to(equal(0))
        expect(self.gpmixin.mapView?.mapType).to(equal(.standard))
        expect(self.gpmixin.mapView?.showsTraffic).toEventually(beTrue())
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithSateliteMap() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let _ = appDelegate.getBaseMap(),
              let _ = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = Int(MKMapType.satellite.rawValue)
        UserDefaults.standard.mapShowTraffic = false
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).to(equal(0))
        expect(self.gpmixin.mapView?.mapType).toEventually(equal(.satellite))
        expect(self.gpmixin.mapView?.showsTraffic).to(beFalse())
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithSateliteMapAndTraffic() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let _ = appDelegate.getBaseMap(),
              let _ = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = Int(MKMapType.satellite.rawValue)
        UserDefaults.standard.mapShowTraffic = true
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).to(equal(0))
        expect(self.gpmixin.mapView?.mapType).toEventually(equal(.satellite))
        // this should still be false because we don't show traffic on satelite maps
        expect(self.gpmixin.mapView?.showsTraffic).to(beFalse())
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithBadMapType() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let _ = appDelegate.getBaseMap(),
              let _ = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = 87
        UserDefaults.standard.mapShowTraffic = false
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).to(equal(0))
        expect(self.gpmixin.mapView?.mapType).to(equal(.standard))
        expect(self.gpmixin.mapView?.showsTraffic).to(beFalse())
    }
    
    @MainActor
    func testGetRendererForBaseMap() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = Int(MKMapType.standard.rawValue)
        UserDefaults.standard.mapShowTraffic = false
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.renderer(overlay: backgroundOverlay)).toEventually(beAKindOf(MKTileOverlayRenderer.self))
        expect(self.gpmixin.renderer(overlay: darkBackgroundOverlay)).toEventually(beAKindOf(MKTileOverlayRenderer.self))
    }
    
    @MainActor
    func testReturnNilForNonBaseMapOverlayWhenAskedForRenderer() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let _ = appDelegate.getBaseMap(),
              let _ = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = Int(MKMapType.standard.rawValue)
        UserDefaults.standard.mapShowTraffic = false
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)

        let overlay = MKTileOverlay()
        
        expect(self.gpmixin.renderer(overlay: overlay)).to(beNil())
    }
    
    @MainActor
    func testInitializeTheGeoPackageBaseMapWithDarkMapAndThenSwitchToLightMap() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = 3
        UserDefaults.standard.themeOverride = 2
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .dark
        }
        tester().wait(forTimeInterval: 0.5)
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .light
        }
        tester().wait(forTimeInterval: 0.5)
        gpmixin.traitCollectionUpdated(previous: nil)
        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).toEventually(equal(backgroundOverlay))
    }
    
    @MainActor
    func testShouldntSwitchTheMapIfTheNewTraitCollectionDoesNotHaveADifferentColorAppearance() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let _ = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = 3
        UserDefaults.standard.themeOverride = 2
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .dark
        }
        tester().wait(forTimeInterval: 0.5)
        let traitCollection = window.traitCollection
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
        // this would never happen like this in real life because something would have changed, but, just for a test
        gpmixin.traitCollectionUpdated(previous: traitCollection)
        expect(self.gpmixin.mapView?.overlays.count).to(equal(1))
        expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
    }
    
    @MainActor
    func testShouldSwitchTheMapIfTheNewTraitCollectionHasADifferentColorAppearance() {
        guard let appDelegate = UIApplication.shared.delegate as? TestingAppDelegate,
              let backgroundOverlay = appDelegate.getBaseMap(),
              let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                  tester().fail()
                  return
              }
        UserDefaults.standard.mapType = 3
        UserDefaults.standard.themeOverride = 2
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .dark
        }
        tester().wait(forTimeInterval: 0.5)
        let traitCollection = window.traitCollection
        let mapState = MapState()
        gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
        if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
            window.overrideUserInterfaceStyle = .light
        }
        tester().wait(forTimeInterval: 0.5)
        // this would never happen like this in real life because something would have changed, but, just for a test
        gpmixin.traitCollectionUpdated(previous: traitCollection)
        expect(self.gpmixin.mapView?.overlays.count).toEventually(equal(1))
        expect(self.gpmixin.mapView?.overlays[0] as? BaseMapOverlay).toEventually(equal(backgroundOverlay))
    }
}
