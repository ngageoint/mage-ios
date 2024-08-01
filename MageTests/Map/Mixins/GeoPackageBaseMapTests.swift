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

class GeoPackageBaseMapTests: KIFSpec {
    
    override func spec() {
        
        describe("GeoPackageBaseMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var gptest: GeoPackageBaseMapTestImpl!
            var gpmixin: GeoPackageBaseMapMixin!
            
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
                Server.setCurrentEventId(1);
                
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
            
            afterEach {
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
            
            it("initialize the GeoPackageBaseMap with dark map") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
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

                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
            }
            
            it("initialize the GeoPackageBaseMap with light map") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
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
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
            }
            
            it("initialize the GeoPackageBaseMap without overridding") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                      let backgroundOverlay = appDelegate.getBaseMap(),
                      let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                          tester().fail()
                          return
                      }
                UserDefaults.standard.mapType = 3
                let mapState = MapState()
                gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0]).to(beAKindOf(BaseMapOverlay.self))
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
                } else {
                    expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
                }
            }
            
            it("initialize the GeoPackageBaseMap with override unspecified") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
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
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0]).to(beAKindOf(BaseMapOverlay.self))
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
                } else {
                    expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
                }
                expect(gpmixin.mapView?.showsTraffic).to(beFalse())
            }
            
            it("initialize the GeoPackageBaseMap with override unspecified and traffic set to yes") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
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
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0]).to(beAKindOf(BaseMapOverlay.self))
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
                } else {
                    expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
                }
                // this should still be false b/c on offline map there is no traffic
                expect(gpmixin.mapView?.showsTraffic).to(beFalse())
            }
            
            it("initialize the GeoPackageBaseMap with online map") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                      let _ = appDelegate.getBaseMap(),
                      let _ = appDelegate.getDarkBaseMap() else {
                          tester().fail()
                          return
                      }
                UserDefaults.standard.mapType = Int(MKMapType.standard.rawValue)
                UserDefaults.standard.mapShowTraffic = false
                let mapState = MapState()
                gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
                expect(gpmixin.mapView?.overlays.count).to(equal(0))
                expect(gpmixin.mapView?.mapType).to(equal(.standard))
                expect(gpmixin.mapView?.showsTraffic).to(beFalse())
            }
            
            it("initialize the GeoPackageBaseMap with online map and traffic") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                      let _ = appDelegate.getBaseMap(),
                      let _ = appDelegate.getDarkBaseMap() else {
                          tester().fail()
                          return
                      }
                UserDefaults.standard.mapType = Int(MKMapType.standard.rawValue)
                UserDefaults.standard.mapShowTraffic = true
                let mapState = MapState()
                gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
                expect(gpmixin.mapView?.overlays.count).to(equal(0))
                expect(gpmixin.mapView?.mapType).to(equal(.standard))
                expect(gpmixin.mapView?.showsTraffic).to(beTrue())
            }
            
            it("initialize the GeoPackageBaseMap with satelite map") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                      let _ = appDelegate.getBaseMap(),
                      let _ = appDelegate.getDarkBaseMap() else {
                          tester().fail()
                          return
                      }
                UserDefaults.standard.mapType = Int(MKMapType.satellite.rawValue)
                UserDefaults.standard.mapShowTraffic = false
                let mapState = MapState()
                gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
                expect(gpmixin.mapView?.overlays.count).to(equal(0))
                expect(gpmixin.mapView?.mapType).to(equal(.satellite))
                expect(gpmixin.mapView?.showsTraffic).to(beFalse())
            }
            
            it("initialize the GeoPackageBaseMap with satelite map and traffic") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                      let _ = appDelegate.getBaseMap(),
                      let _ = appDelegate.getDarkBaseMap() else {
                          tester().fail()
                          return
                      }
                UserDefaults.standard.mapType = Int(MKMapType.satellite.rawValue)
                UserDefaults.standard.mapShowTraffic = true
                let mapState = MapState()
                gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
                expect(gpmixin.mapView?.overlays.count).to(equal(0))
                expect(gpmixin.mapView?.mapType).to(equal(.satellite))
                // this should still be false because we don't show traffic on satelite maps
                expect(gpmixin.mapView?.showsTraffic).to(beFalse())
            }
            
            it("initialize the GeoPackageBaseMap with bad map type") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                      let _ = appDelegate.getBaseMap(),
                      let _ = appDelegate.getDarkBaseMap() else {
                          tester().fail()
                          return
                      }
                UserDefaults.standard.mapType = 87
                UserDefaults.standard.mapShowTraffic = false
                let mapState = MapState()
                gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
                expect(gpmixin.mapView?.overlays.count).to(equal(0))
                expect(gpmixin.mapView?.mapType).to(equal(.standard))
                expect(gpmixin.mapView?.showsTraffic).to(beFalse())
            }
            
            it("get renderer for base map") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                      let backgroundOverlay = appDelegate.getBaseMap(),
                      let darkBackgroundOverlay = appDelegate.getDarkBaseMap() else {
                          tester().fail()
                          return
                      }
                UserDefaults.standard.mapType = Int(MKMapType.standard.rawValue)
                UserDefaults.standard.mapShowTraffic = false
                let mapState = MapState()
                gpmixin.setupMixin(mapView: gptest.mapView!, mapState: mapState)
                expect(gpmixin.renderer(overlay: backgroundOverlay)).to(beAKindOf(MKTileOverlayRenderer.self))
                expect(gpmixin.renderer(overlay: darkBackgroundOverlay)).to(beAKindOf(MKTileOverlayRenderer.self))
            }
            
            it("return nil for non base map overlay when asked for renderer") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
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
                
                expect(gpmixin.renderer(overlay: overlay)).to(beNil())
            }
            
            it("initialize the GeoPackageBaseMap with dark map and then switch to light map") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
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
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
                if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                    window.overrideUserInterfaceStyle = .light
                }
                tester().wait(forTimeInterval: 0.5)
                gpmixin.traitCollectionUpdated(previous: nil)
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
            }
            
            it("shouldn't switch the map if the new trait collection does not have a different color appearance") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
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
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
                // this would never happen like this in real life because something would have changed, but, just for a test
                gpmixin.traitCollectionUpdated(previous: traitCollection)
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
            }
            
            it("should switch the map if the new trait collection has a different color appearance") {
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
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
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(darkBackgroundOverlay))
                if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                    window.overrideUserInterfaceStyle = .light
                }
                tester().wait(forTimeInterval: 0.5)
                // this would never happen like this in real life because something would have changed, but, just for a test
                gpmixin.traitCollectionUpdated(previous: traitCollection)
                expect(gpmixin.mapView?.overlays.count).to(equal(1))
                expect(gpmixin.mapView?.overlays[0] as? BaseMapOverlay).to(equal(backgroundOverlay))
            }
        }
    }
}
