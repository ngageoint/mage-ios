//
//  FollowUserTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/21/22.
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

class FollowUserTestImpl : NSObject, FollowUser {
    var mapView: MKMapView?
    
    var followUserMapMixin: FollowUserMapMixin?
}

extension FollowUserTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return followUserMapMixin?.renderer(overlay: overlay) ?? followUserMapMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return followUserMapMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class FollowUserTests: KIFSpec {
    
    override func spec() {
        
        describe("FollowUserTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: FollowUserTestImpl!
            var mixin: FollowUserMapMixin!
            var userabc: User!
            
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
                UserDefaults.standard.selectedStaticLayers = nil
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "userabc")
                userabc = User.mr_findFirst(byAttribute: "remoteId", withValue: "userabc")
                MageCoreDataFixtures.addUser(userId: "userdef")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userdef")
                
                controller = UIViewController()
                let mapView = MKMapView()
                controller.view = mapView
                
                testimpl = FollowUserTestImpl()
                testimpl.mapView = mapView
                mapView.delegate = testimpl
                
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
            
            it("initialize the FollowUserMapMixin with a user") {
                
                UserDefaults.standard.currentUserId = nil

                MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)
                
                mixin = FollowUserMapMixin(followUser: testimpl, user: userabc, scheme: MAGEScheme.scheme())
                testimpl.followUserMapMixin = mixin
                
                mixin.setupMixin()
                
                let initialLocation = userabc.coordinate
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.01))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the FollowUserMapMixin with a user then move it") {
                
                UserDefaults.standard.currentUserId = nil
                
                MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)
                
                mixin = FollowUserMapMixin(followUser: testimpl, user: userabc, scheme: MAGEScheme.scheme())
                testimpl.followUserMapMixin = mixin
                
                mixin.setupMixin()
                
                let initialLocation = userabc.coordinate
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.01))
            
                MageCoreDataFixtures.addLocation(userId: "userabc", geometry: SFPoint(xValue: initialLocation.longitude + 1, andYValue: initialLocation.latitude + 1), completion: nil)
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude + 1, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude + 1, within: 0.01))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the FollowUserMapMixin with a user with no location then add one") {
                
                UserDefaults.standard.currentUserId = nil
                                
                mixin = FollowUserMapMixin(followUser: testimpl, user: userabc, scheme: MAGEScheme.scheme())
                testimpl.followUserMapMixin = mixin
                
                mixin.setupMixin()
                
                MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                
                let initialLocation = userabc.coordinate
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.01))
                
                MageCoreDataFixtures.addLocation(userId: "userabc", geometry: SFPoint(xValue: initialLocation.longitude + 1, andYValue: initialLocation.latitude + 1), completion: nil)
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude + 1, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude + 1, within: 0.01))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the FollowUserMapMixin with a user then stop following and move it") {
                
                UserDefaults.standard.currentUserId = nil
                
                MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)
                
                mixin = FollowUserMapMixin(followUser: testimpl, user: userabc, scheme: MAGEScheme.scheme())
                testimpl.followUserMapMixin = mixin
                
                mixin.setupMixin()
                
                let initialLocation = userabc.coordinate
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.01))
                
                mixin.followUser(user: nil)
                
                MageCoreDataFixtures.addLocation(userId: "userabc", geometry: SFPoint(xValue: initialLocation.longitude + 1, andYValue: initialLocation.latitude + 1), completion: nil)
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.01))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the FollowUserMapMixin with no user then follow then move it") {
                
                UserDefaults.standard.currentUserId = nil
                
                MageCoreDataFixtures.addLocation(userId: "userabc", completion: nil)
                MageCoreDataFixtures.addLocation(userId: "userdef", completion: nil)
                
                mixin = FollowUserMapMixin(followUser: testimpl, user: nil, scheme: MAGEScheme.scheme())
                testimpl.followUserMapMixin = mixin
                
                mixin.setupMixin()
                
                let initialLocation = userabc.coordinate
                
                expect(mixin.mapView?.centerCoordinate.latitude).toNot(beCloseTo(initialLocation.latitude, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toNot(beCloseTo(initialLocation.longitude, within: 0.01))
                
                mixin.user = userabc
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.01))
                
                MageCoreDataFixtures.addLocation(userId: "userabc", geometry: SFPoint(xValue: initialLocation.longitude + 1, andYValue: initialLocation.latitude + 1), completion: nil)
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude + 1, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude + 1, within: 0.01))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the FollowUserMapMixin with me then move me") {
                
                UserDefaults.standard.currentUserId = "userabc"
                
                MageCoreDataFixtures.addGPSLocation(userId: "userabc", completion: nil)
                
                mixin = FollowUserMapMixin(followUser: testimpl, user: userabc, scheme: MAGEScheme.scheme())
                testimpl.followUserMapMixin = mixin
                
                mixin.setupMixin()
                
                let initialLocation = userabc.coordinate
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.01))
                
                MageCoreDataFixtures.addGPSLocation(userId: "userabc", location: CLLocation(latitude: initialLocation.latitude + 1, longitude: initialLocation.longitude + 1), completion: nil)
                
                expect(mixin.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude + 1, within: 0.01))
                expect(mixin.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude + 1, within: 0.01))
                
                mixin.cleanupMixin()
            }
        }
    }
}
