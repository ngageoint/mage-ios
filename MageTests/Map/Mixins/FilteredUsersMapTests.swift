//
//  FilteredUsersMapTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/9/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs
import MagicalRecord

@testable import MAGE

class FilteredUsersMapTestImpl : NSObject, FilteredUsersMap {
    var mapView: MKMapView?
    
    var filteredUsersMapMixin: FilteredUsersMapMixin?
}

extension FilteredUsersMapTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return filteredUsersMapMixin?.renderer(overlay: overlay) ?? filteredUsersMapMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return filteredUsersMapMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class FilteredUsersMapTests: KIFSpec {
    
    override func spec() {
        
        describe("FilteredUsersMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: FilteredUsersMapTestImpl!
            var mixin: FilteredUsersMapMixin!
            
            describe("show user") {
                
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
                    
                    expect(User.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "User still exist in default");
                    
                    expect(User.mr_findAll(in: NSManagedObjectContext.mr_rootSaving())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(200), description: "User still exist in root");
                    UserDefaults.standard.baseServerUrl = "https://magetest";
                    
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                    let user = MageCoreDataFixtures.addUser(userId: "userabc")
                    MageCoreDataFixtures.addUser(userId: "userdef")
                    MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                    MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userdef")
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)
                    
                    Server.setCurrentEventId(1);
                    UserDefaults.standard.currentUserId = "userabc";
                    
                    
                    controller = UIViewController()
                    let mapView = MKMapView()
                    controller.view = mapView
                    
                    testimpl = FilteredUsersMapTestImpl()
                    testimpl.mapView = mapView
                    
                    mixin = FilteredUsersMapMixin(filteredUsersMap: testimpl, user: user, scheme: MAGEScheme.scheme())
                    testimpl.filteredUsersMapMixin = mixin
                    
                    navController = UINavigationController(rootViewController: controller);
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
                
                it("initialize the FilteredObservationsMap with one user") {
                    TimeFilter.setLocation(.all)
                    
                    mixin.setupMixin()
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    let la : LocationAnnotation = mixin.mapView!.annotations[0] as! LocationAnnotation
                    expect(la.user?.remoteId).to(equal("userabc"))
                    mixin.cleanupMixin()
                }
            }
            
            describe("show all users") {
                
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
                    
                    expect(User.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "User still exist in default");
                    
                    expect(User.mr_findAll(in: NSManagedObjectContext.mr_rootSaving())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(200), description: "User still exist in root");
                    UserDefaults.standard.baseServerUrl = "https://magetest";
                    
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                    MageCoreDataFixtures.addUser(userId: "userabc")
                    MageCoreDataFixtures.addUser(userId: "userdef")
                    MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                    MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userdef")
                    
                    Server.setCurrentEventId(1);
                    UserDefaults.standard.currentUserId = "userabc";
                    
                    
                    controller = UIViewController()
                    let mapView = MKMapView()
                    controller.view = mapView
                    
                    testimpl = FilteredUsersMapTestImpl()
                    testimpl.mapView = mapView
                    
                    mixin = FilteredUsersMapMixin(filteredUsersMap: testimpl, scheme: MAGEScheme.scheme())
                    testimpl.filteredUsersMapMixin = mixin
                    
                    navController = UINavigationController(rootViewController: controller);
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
                
                fit("initialize the FilteredObservationsMap with all users") {
                    TimeFilter.setLocation(.all)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)
                    
                    mixin.setupMixin()
                    expect(mixin.mapView?.annotations.count).toEventually(equal(2))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    for annotation in mixin.mapView!.annotations {
                        let la : LocationAnnotation = annotation as! LocationAnnotation
                        expect(la.user?.remoteId == "userabc" || la.user?.remoteId == "userdef").to(beTrue())
                    }
                    mixin.cleanupMixin()
                }
            }
        }
    }
}
