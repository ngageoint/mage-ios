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
import MapFramework

@testable import MAGE
import CoreLocation

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
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

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
                    MageCoreDataFixtures.addUser(userId: "userxyz")
                    MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userxyz")
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
                
                it("initialize the FilteredObservationsMap with all users") {
                    TimeFilter.setLocation(.all)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userxyz", date: Date(), completion: nil)

                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    // two because current user is filtered out
                    expect(mixin.mapView?.annotations.count).toEventually(equal(2))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    for annotation in mixin.mapView!.annotations {
                        let la : LocationAnnotation = annotation as! LocationAnnotation
                        expect(la.user?.remoteId == "userdef" || la.user?.remoteId == "userxyz").to(beTrue())
                    }
                    mixin.cleanupMixin()
                }
                
                it("initialize the FilteredObservationsMap with all users last 24 hours") {
                    TimeFilter.setLocation(.last24Hours)
                    let longAgo = Date(timeIntervalSince1970: 1)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userxyz", date: longAgo, completion: nil)
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    // one because current user is filtered out
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    for annotation in mixin.mapView!.annotations {
                        let la : LocationAnnotation = annotation as! LocationAnnotation
                        expect(la.user?.remoteId).to(equal("userdef"))
                    }
                    mixin.cleanupMixin()
                }
                
                it("initialize the FilteredObservationsMap with all users with all filter then change the filter") {
                    TimeFilter.setLocation(.all)
                    let longAgo = Date(timeIntervalSince1970: 1)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userxyz", date: longAgo, completion: nil)
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    // two because current user is filtered out
                    expect(mixin.mapView?.annotations.count).toEventually(equal(2))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    for annotation in mixin.mapView!.annotations {
                        let la : LocationAnnotation = annotation as! LocationAnnotation
                        expect(la.user?.remoteId == "userdef" || la.user?.remoteId == "userxyz").to(beTrue())
                    }
                    
                    TimeFilter.setLocation(.lastWeek)
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    for annotation in mixin.mapView!.annotations {
                        let la : LocationAnnotation = annotation as! LocationAnnotation
                        expect(la.user?.remoteId).to(equal("userdef"))
                    }

                    mixin.cleanupMixin()
                }
                
                it("initialize the FilteredObservationsMap with all users last week") {
                    TimeFilter.setLocation(.lastWeek)
                    let longAgo = Date(timeIntervalSince1970: 1)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userxyz", date: longAgo, completion: nil)
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    // one because current user is filtered out
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    for annotation in mixin.mapView!.annotations {
                        let la : LocationAnnotation = annotation as! LocationAnnotation
                        expect(la.user?.remoteId).to(equal("userdef"))
                    }
                    mixin.cleanupMixin()
                }
                
                it("initialize the FilteredObservationsMap with all users last month") {
                    TimeFilter.setLocation(.lastMonth)
                    let longAgo = Date(timeIntervalSince1970: 1)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", date: Date(), completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userxyz", date: longAgo, completion: nil)
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    // one because current user is filtered out
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    for annotation in mixin.mapView!.annotations {
                        let la : LocationAnnotation = annotation as! LocationAnnotation
                        expect(la.user?.remoteId).to(equal("userdef"))
                    }
                    mixin.cleanupMixin()
                }
                
                it("initialize the FilteredObservationsMap with all users add location later") {
                    TimeFilter.setLocation(.all)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    expect(mixin.mapView?.annotations.count).toEventually(equal(0))
                    
                    MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)

                    // one because current user is filtered out
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    var initialLocation: CLLocation?
                    for annotation in mixin.mapView!.annotations {
                        let la : LocationAnnotation = annotation as! LocationAnnotation
                        expect(la.user?.remoteId).to(equal("userdef"))
                        initialLocation = la.location
                    }
                    
                    guard let initialLocation = initialLocation else {
                        tester().fail()
                        return
                    }

                    MageCoreDataFixtures.addLocation(userId: "userdef", geometry: SFPoint(xValue: initialLocation.coordinate.longitude + 1.0, andYValue: initialLocation.coordinate.latitude + 1.0), completion: nil)
                    
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    expect((mixin.mapView?.annotations[0] )!.coordinate.longitude).toEventually(beCloseTo(initialLocation.coordinate.longitude + 1.0))
                    expect((mixin.mapView?.annotations[0] )!.coordinate.latitude).toEventually(beCloseTo(initialLocation.coordinate.latitude + 1.0))
                    
                    mixin.cleanupMixin()
                }
                
                it("focus on the annotation then clear focus") {
                    
                    mixin.mapView?.delegate = testimpl
                    
                    TimeFilter.setLocation(.all)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    // one because current user is filtered out
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    var initialLocation: CLLocation?
                    var originalHeight = 0.0
                    var la: LocationAnnotation?
                    for annotation in mixin.mapView!.annotations {
                        la = annotation as? LocationAnnotation
                        guard let la = la else {
                            tester().fail()
                            return
                        }

                        expect(la.user?.remoteId).to(equal("userdef"))
                        initialLocation = la.location
                        
                        guard let initialLocation = initialLocation else {
                            tester().fail()
                            return
                        }
                        
                        if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                            mixin.mapView?.setRegion(region, animated: false)
                        }
                        
                        expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.coordinate.latitude, within: 0.1))
                        expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.coordinate.longitude, within: 0.1))
                        
                        expect(la.view).to(beAKindOf(PersonAnnotationView.self))
                        if let lav = la.view as? PersonAnnotationView {
                            originalHeight = lav.frame.size.height
                            expect(lav.isEnabled).to(beFalse())
                            expect(lav.canShowCallout).to(beFalse())
                            expect(lav.accessibilityLabel).to(equal("Location Annotation \(la.user .objectID.uriRepresentation().absoluteString)"))
                            expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))
                        }
                    }
                    
                    let notification = MapAnnotationFocusedNotification(annotation: la, mapView: mixin.mapView)
                    NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                    

                    if let la = mixin.mapView?.annotations[0] as? LocationAnnotation {
                        expect(la.view).to(beAKindOf(PersonAnnotationView.self))
                        if let lav = la.view as? PersonAnnotationView {
                            expect(lav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                            expect(mixin.enlargedLocationView).to(equal(lav))
                        }
                    }
                    
                    NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
                    expect(mixin.enlargedLocationView).toEventually(beNil())
                    if let la = mixin.mapView?.annotations[0] as? LocationAnnotation {
                        expect(la.view).to(beAKindOf(PersonAnnotationView.self))
                        if let lav = la.view as? PersonAnnotationView {
                            expect(lav.frame.size.height).toEventually(equal(originalHeight))
                        }
                    }
                    
                    mixin.cleanupMixin()
                }
                
                it("focus on the annotation then focus on a different one") {
                    
                    mixin.mapView?.delegate = testimpl
                    
                    TimeFilter.setLocation(.all)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userxyz", completion: nil)
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    // one because current user is filtered out
                    expect(mixin.mapView?.annotations.count).toEventually(equal(2))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    var initialLocation: CLLocation?
                    var originalHeight = 0.0
                    var defla: LocationAnnotation?
                    for annotation in mixin.mapView!.annotations {
                        defla = annotation as? LocationAnnotation
                        guard let defla = defla else {
                            tester().fail()
                            return
                        }
                        
                        if defla.user?.remoteId == "userdef" {
                            initialLocation = defla.location
                            
                            guard let initialLocation = initialLocation else {
                                tester().fail()
                                return
                            }
                            
                            if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                                mixin.mapView?.setRegion(region, animated: false)
                            }
                            
                            expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.coordinate.latitude, within: 0.1))
                            expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.coordinate.longitude, within: 0.1))
                            
                            expect(defla.view).to(beAKindOf(PersonAnnotationView.self))
                            if let lav = defla.view as? PersonAnnotationView {
                                originalHeight = lav.frame.size.height
                                expect(lav.isEnabled).to(beFalse())
                                expect(lav.canShowCallout).to(beFalse())
                                expect(lav.accessibilityLabel).to(equal("Location Annotation \(defla.user .objectID.uriRepresentation().absoluteString)"))
                                expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))
                            
                                let notification = MapAnnotationFocusedNotification(annotation: defla, mapView: mixin.mapView)
                                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                                expect(lav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                                expect(mixin.enlargedLocationView).to(equal(lav))
                            } else {
                                tester().fail()
                            }
                        }
                    }
                    
                    var xyzla: LocationAnnotation?
                    for annotation in mixin.mapView!.annotations {
                        xyzla = annotation as? LocationAnnotation
                        guard let xyzla = xyzla else {
                            tester().fail()
                            return
                        }
                        
                        if xyzla.user?.remoteId == "userxyz" {
                            initialLocation = xyzla.location
                            
                            guard let initialLocation = initialLocation else {
                                tester().fail()
                                return
                            }
                            
                            if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                                mixin.mapView?.setRegion(region, animated: false)
                            }
                            
                            expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.coordinate.latitude, within: 0.1))
                            expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.coordinate.longitude, within: 0.1))
                            
                            expect(xyzla.view).to(beAKindOf(PersonAnnotationView.self))
                            if let lav = xyzla.view as? PersonAnnotationView {
                                originalHeight = lav.frame.size.height
                                expect(lav.isEnabled).to(beFalse())
                                expect(lav.canShowCallout).to(beFalse())
                                expect(lav.accessibilityLabel).to(equal("Location Annotation \(xyzla.user .objectID.uriRepresentation().absoluteString)"))
                                expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))
                            
                                let notification = MapAnnotationFocusedNotification(annotation: xyzla, mapView: mixin.mapView)
                                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                                expect(lav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                                expect(mixin.enlargedLocationView).to(equal(lav))
                            } else {
                                tester().fail()
                            }
                        }
                    }
                    
                    for annotation in mixin.mapView!.annotations {
                        defla = annotation as? LocationAnnotation
                        guard let defla = defla else {
                            tester().fail()
                            return
                        }
                        
                        if defla.user?.remoteId == "userdef" {
                            if let lav = defla.view as? PersonAnnotationView {
                                expect(lav.frame.size.height).toEventually(equal(originalHeight))
                            } else {
                                tester().fail()
                            }
                        }
                    }
                
                    mixin.cleanupMixin()
                }
                
                it("focus on the annotation then get an update and the view should still be enlarged") {
                    
                    mixin.mapView?.delegate = testimpl
                    
                    TimeFilter.setLocation(.all)
                    
                    MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                    MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)
                    
                    let mapState = MapState()
                    mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                    // one because current user is filtered out
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0]).to(beAKindOf(LocationAnnotation.self))
                    var initialLocation: CLLocation?
                    var originalHeight = 0.0
                    var defla: LocationAnnotation?
                    for annotation in mixin.mapView!.annotations {
                        defla = annotation as? LocationAnnotation
                        guard let defla = defla else {
                            tester().fail()
                            return
                        }
                        
                        if defla.user?.remoteId == "userdef" {
                            initialLocation = defla.location
                            
                            guard let initialLocation = initialLocation else {
                                tester().fail()
                                return
                            }
                            
                            if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                                mixin.mapView?.setRegion(region, animated: false)
                            }
                            
                            expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.coordinate.latitude, within: 0.1))
                            expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.coordinate.longitude, within: 0.1))
                            
                            expect(defla.view).to(beAKindOf(PersonAnnotationView.self))
                            if let lav = defla.view as? PersonAnnotationView {
                                originalHeight = lav.frame.size.height
                                expect(lav.isEnabled).to(beFalse())
                                expect(lav.canShowCallout).to(beFalse())
                                expect(lav.accessibilityLabel).to(equal("Location Annotation \(defla.user .objectID.uriRepresentation().absoluteString)"))
                                expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))
                                
                                let notification = MapAnnotationFocusedNotification(annotation: defla, mapView: mixin.mapView)
                                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                                expect(lav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                                expect(mixin.enlargedLocationView).to(equal(lav))
                            } else {
                                tester().fail()
                            }
                        }
                    }
                    
                    guard let initialLocation = initialLocation else {
                        tester().fail()
                        return
                    }
                    
                    MageCoreDataFixtures.addLocation(userId: "userdef", geometry: SFPoint(xValue: initialLocation.coordinate.longitude + 1.0, andYValue: initialLocation.coordinate.latitude + 1.0), completion: nil)
                    
                    expect(mixin.mapView?.annotations.count).toEventually(equal(1))
                    expect(mixin.mapView?.annotations[0].coordinate.longitude).toEventually(beCloseTo(initialLocation.coordinate.longitude + 1.0))
                    expect(mixin.mapView?.annotations[0].coordinate.latitude).toEventually(beCloseTo(initialLocation.coordinate.latitude + 1.0))
                    
                    if let region = mixin.mapView?.regionThatFits(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: initialLocation.coordinate.latitude + 1.0, longitude: initialLocation.coordinate.longitude + 1.0), latitudinalMeters: 100000, longitudinalMeters: 10000)) {
                        mixin.mapView?.setRegion(region, animated: false)
                    }
                    
                    expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.coordinate.latitude + 1.0, within: 0.1))
                    expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.coordinate.longitude + 1.0, within: 0.1))
                    
                    for annotation in mixin.mapView!.annotations {
                        defla = annotation as? LocationAnnotation
                        guard let defla = defla else {
                            tester().fail()
                            return
                        }
                        
                        if defla.user?.remoteId == "userdef" {
                            
                            expect(defla.view).to(beAKindOf(PersonAnnotationView.self))
                            if let lav = defla.view as? PersonAnnotationView {
                                expect(lav.isEnabled).to(beFalse())
                                expect(lav.canShowCallout).to(beFalse())
                                expect(lav.accessibilityLabel).to(equal("Location Annotation \(defla.user .objectID.uriRepresentation().absoluteString)"))
                                expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))
                                
                                let notification = MapAnnotationFocusedNotification(annotation: defla, mapView: mixin.mapView)
                                NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                                expect(lav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                                expect(mixin.enlargedLocationView).to(equal(lav))
                            } else {
                                tester().fail()
                            }
                        }
                    }
                                        
                    mixin.cleanupMixin()
                }
            }
        }
    }
}
