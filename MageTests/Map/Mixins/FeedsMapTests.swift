//
//  FeedsMapTests.swift
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
import MapFramework

@testable import MAGE
import CoreLocation
import MapKit

class FeedsMapTestImpl : NSObject, FeedsMap {
    var scheme: MDCContainerScheming?
    var mapView: MKMapView?
    
    var feedsMapMixin: FeedsMapMixin?
}

extension FeedsMapTestImpl : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return feedsMapMixin?.renderer(overlay: overlay) ?? feedsMapMixin?.standardRenderer(overlay: overlay) ?? MKTileOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return feedsMapMixin?.viewForAnnotation(annotation: annotation, mapView: mapView)
    }
}

class FeedsMapTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("FeedsMapTests") {
            var navController: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            var controller: UIViewController!
            var testimpl: FeedsMapTestImpl!
            var mixin: FeedsMapMixin!
            
            var coreDataStack: TestCoreDataStack?
            var context: NSManagedObjectContext!
            
            beforeEach {
                
                if (navController != nil) {
                    waitUntil { done in
                        navController.dismiss(animated: false, completion: {
                            done();
                        });
                    }
                }
                coreDataStack = TestCoreDataStack()
                context = coreDataStack!.persistentContainer.newBackgroundContext()
                InjectedValues[\.nsManagedObjectContext] = context
//                TestHelpers.clearAndSetUpStack();
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
                
                MageCoreDataFixtures.addEvent(context: context, remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                Server.setCurrentEventId(1);
                
                UserDefaults.standard.currentEventSelectedFeeds = []
                
                controller = UIViewController()
                let mapView = MKMapView()
                controller.view = mapView
                
                testimpl = FeedsMapTestImpl()
                testimpl.mapView = mapView
                testimpl.scheme = MAGEScheme.scheme()
                mapView.delegate = testimpl
                
                navController = UINavigationController(rootViewController: controller);
                
                mixin = FeedsMapMixin(feedsMap: testimpl)
                testimpl.feedsMapMixin = mixin
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
                UserDefaults.standard.currentEventSelectedFeeds = []

                UserDefaults.standard.mapRegion = MKCoordinateRegion(center: kCLLocationCoordinate2DInvalid, span: MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 0));
                
                if let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first {
                    window.overrideUserInterfaceStyle = .unspecified
                }
                window?.resignKey();
                window.rootViewController = nil;
                navController = nil;
                view = nil;
                window = nil;
                InjectedValues[\.nsManagedObjectContext] = nil
                coreDataStack!.reset()
//                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs()
            }
            
            it("initialize the FeedsMap") {
                MageCoreDataFixtures.addFeedToEvent()
                MageCoreDataFixtures.addFeedItemToFeed(properties: nil)
                
                UserDefaults.standard.currentEventSelectedFeeds = []
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the FeedsMap with selected feed") {
                MageCoreDataFixtures.addFeedToEvent()
                MageCoreDataFixtures.addFeedItemToFeed(properties: nil)
                
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2")
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "2", properties: nil)
                
                UserDefaults.standard.currentEventSelectedFeeds = ["1", "2"]
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(2))
                
                mixin.cleanupMixin()
            }
            
            it("initialize the FeedsMap with selected feed remove one") {
                MageCoreDataFixtures.addFeedToEvent()
                MageCoreDataFixtures.addFeedItemToFeed(properties: nil)
                
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2")
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "2", properties: nil)
                
                UserDefaults.standard.currentEventSelectedFeeds = ["1", "2"]
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(2))
                
                // unselect one of the feeds
                UserDefaults.standard.currentEventSelectedFeeds = ["1"]
                
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(1))
                
                mixin.cleanupMixin()
            }
            
            it("add a new feed") {
                MageCoreDataFixtures.addFeedToEvent()
                MageCoreDataFixtures.addFeedItemToFeed(properties: nil)
                
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2")
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "2", properties: nil)
                
                UserDefaults.standard.currentEventSelectedFeeds = []
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(0))
                
                // unselect one of the feeds
                UserDefaults.standard.currentEventSelectedFeeds = ["1"]
                
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(1))
                
                mixin.cleanupMixin()
            }
            
            it("add a new feed item") {
                MageCoreDataFixtures.addFeedToEvent()
                MageCoreDataFixtures.addFeedItemToFeed(properties: nil)
                
                UserDefaults.standard.currentEventSelectedFeeds = ["1"]
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(1))
                
                MageCoreDataFixtures.addFeedItemToFeed(properties: nil)
                
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(2))
                
                mixin.cleanupMixin()
            }
            
            it("move a feed item") {
                MageCoreDataFixtures.addFeedToEvent()
                MageCoreDataFixtures.addFeedItemToFeed(properties: nil, simpleFeature: SFPoint(x: -105.11, andY: 40.11))
                
                UserDefaults.standard.currentEventSelectedFeeds = ["1"]
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)

                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(1))
                
                expect(testimpl.mapView?.annotations[0]).to(beAKindOf(FeedItem.self))
                let feedItem = testimpl.mapView!.annotations[0] as! FeedItem
                let initialLocation: CLLocationCoordinate2D = feedItem.coordinate
                expect(initialLocation.latitude).to(beCloseTo(40.11))
                expect(initialLocation.longitude).to(beCloseTo(-105.11))
                
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: initialLocation, latitudinalMeters: 5000, longitudinalMeters: 5000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }
                
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.01))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.01))
                
                feedItem.simpleFeature = SFPoint(x: -105.3, andY: 40.3)
                
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(1))
                
                let movedFeedItem = testimpl.mapView!.annotations[0] as! FeedItem
                let newLocation = movedFeedItem.coordinate
                expect(newLocation.latitude).to(beCloseTo(40.3))
                expect(newLocation.longitude).to(beCloseTo(-105.3))
                testimpl.mapView?.setCenter(newLocation, animated: false)
                
                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(newLocation.latitude, within: 0.01))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(newLocation.longitude, within: 0.01))
                                
                mixin.cleanupMixin()
            }
            
            it("focus on the feed item") {
                MageCoreDataFixtures.addFeedToEvent()
                MageCoreDataFixtures.addFeedItemToFeed(properties: nil, simpleFeature: SFPoint(x: -105.11, andY: 40.11))
                MageCoreDataFixtures.addFeedItemToFeed(properties: nil, simpleFeature: SFPoint(x: -105.1, andY: 40.1))
                
                UserDefaults.standard.currentEventSelectedFeeds = ["1"]
                
                let mapState = MapState()
                mixin.setupMixin(mapView: testimpl.mapView!, mapState: mapState)
                
                expect(testimpl.mapView?.overlays.count).to(equal(0))
                expect(testimpl.mapView?.annotations.count).to(equal(2))
                
                expect(testimpl.mapView?.annotations[0]).to(beAKindOf(FeedItem.self))
                let feedItem = testimpl.mapView!.annotations[0] as! FeedItem
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: feedItem.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }
                
                var initialLocation: CLLocationCoordinate2D = feedItem.coordinate
                var originalHeight = 0.0

                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.1))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.1))

                expect(feedItem.view).to(beAKindOf(MKAnnotationView.self))
                if let av = feedItem.view {
                    originalHeight = av.frame.size.height
                    expect(av.isEnabled).to(beFalse())
                    expect(av.canShowCallout).to(beFalse())
                    expect(av.centerOffset).to(equal(CGPoint(x: 0, y: -((av.frame.size.height) / 2.0))))

                    let notification = MapAnnotationFocusedNotification(annotation: feedItem, mapView: testimpl.mapView)
                    NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                    expect(av.frame.size.height).toEventually(equal(originalHeight * 2.0))
                    expect(mixin.enlargedAnnotationView).to(equal(av))

                    // post again, ensure it doesn't double in size again
                    NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification)
                    expect(mixin.enlargedAnnotationView).to(equal(av))
                    expect(av.frame.size.height).toEventually(equal(originalHeight * 2.0))
                }

                // focus on a different one
                expect(testimpl.mapView?.annotations[1]).to(beAKindOf(FeedItem.self))
                let feedItem2 = testimpl.mapView!.annotations[1] as! FeedItem
                initialLocation = feedItem2.coordinate
                
                if let region = testimpl.mapView?.regionThatFits(MKCoordinateRegion(center: feedItem2.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)) {
                    testimpl.mapView?.setRegion(region, animated: false)
                }

                expect(testimpl.mapView?.centerCoordinate.latitude).toEventually(beCloseTo(initialLocation.latitude, within: 0.1))
                expect(testimpl.mapView?.centerCoordinate.longitude).toEventually(beCloseTo(initialLocation.longitude, within: 0.1))

                expect(feedItem2.view).to(beAKindOf(MKAnnotationView.self))
                if let lav = feedItem2.view {
                    originalHeight = lav.frame.size.height
                    expect(lav.isEnabled).to(beFalse())
                    expect(lav.canShowCallout).to(beFalse())
                    expect(lav.centerOffset).to(equal(CGPoint(x: 0, y: -((lav.frame.size.height) / 2.0))))

                    let notification2 = MapAnnotationFocusedNotification(annotation: feedItem2, mapView: testimpl.mapView)
                    NotificationCenter.default.post(name: .MapAnnotationFocused, object: notification2)
                    expect(lav.frame.size.height).toEventually(equal(originalHeight * 2.0))
                    expect(mixin.enlargedAnnotationView).to(equal(lav))
                }

                NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
                expect(mixin.enlargedAnnotationView).toEventually(beNil())

                for annotation in testimpl.mapView!.annotations {
                    if let la = annotation as? FeedItem {
                        expect(la.view).to(beAKindOf(MKAnnotationView.self))
                        if let lav = la.view {
                            expect(lav.frame.size.height).toEventually(equal(originalHeight))
                        }
                    }
                }
                
                mixin.cleanupMixin()
            }
        }
    }
}
