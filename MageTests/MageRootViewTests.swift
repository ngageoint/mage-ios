//
//  MageRootViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots
import PureLayout
import OHHTTPStubs
import XCTest

@testable import MAGE

@available(iOS 13.0, *)
class MageRootViewTests: KIFSpec {
    
    override func spec() {
        
        // skipping these map tests until the map delegate can be fixed
        xdescribe("MageRootView") {
            
            var controller: MageRootViewController!
            var window: UIWindow!;

            func loadFeedsJson() -> NSArray {
                guard let pathString = Bundle(for: type(of: self)).path(forResource: "feeds", ofType: "json") else {
                    fatalError("feeds.json not found")
                }
                
                guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
                    fatalError("Unable to convert feeds.json to String")
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    fatalError("Unable to convert feeds.json to Data")
                }
                
                guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else {
                    fatalError("Unable to convert feeds.json to JSON dictionary")
                }
                
                return jsonDictionary;
            }
            
            func loadFeedItemsJson() -> NSArray {
                guard let pathString = Bundle(for: type(of: self)).path(forResource: "feed1Items", ofType: "json") else {
                    fatalError("feed1Items.json not found")
                }
                
                guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
                    fatalError("Unable to convert feed1Items.json to String")
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    fatalError("Unable to convert feed1Items.json to Data")
                }
                
                guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? NSArray else {
                    fatalError("Unable to convert feed1Items.json to JSON dictionary")
                }
                
                return jsonDictionary;
            }

            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                stub(condition: isHost("magetest")) { (request) -> HTTPStubsResponse in
                    return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil);
                };
                
                MockMageServer.initializeHttpStubs();
                window = TestHelpers.getKeyWindowVisible();
                
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm");
                MageCoreDataFixtures.addUser(userId: "user")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                UserDefaults.standard.currentUserId = "user";
                Server.setCurrentEventId(1);
            }

            afterEach {
                controller.dismiss(animated: false)
                window.rootViewController = nil;
                controller = nil;
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("no feeds") {

                let mapDelegate: MockMapViewDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
                }

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme());
                window.rootViewController = controller;
                
                tester().waitForAnimationsToFinish();

                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.mapView?.delegate = mapDelegate
                tester().waitForAnimationsToFinish();

                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                tester().waitForAnimationsToFinish();

                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(0, 0), animated: false)

                tester().waitForAnimationsToFinish()
            }

            it("one feed") {

                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed")

                let mapDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in

                }

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;

                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                mapViewController?.mapView?.delegate = mapDelegate
                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(0, 0), animated: false)

                window.rootViewController = controller;

            }

            // when brand new feeds are added, they are automatically enabled
            it("two mappable feeds and two non mappable brand new") {

                MageCoreDataFixtures.populateFeedsFromJson();
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "0")
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "1")
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "2")
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "3")
                
                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;
                
                let mapDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in

                }
                
                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                mapViewController?.mapView?.delegate = mapDelegate
                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(40.0085, -104.2678), animated: false)

            }

            it("two mappable feeds and two non mappable one selected") {
                
                MageCoreDataFixtures.populateFeedsFromJson();
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "0")
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "1")
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "2")
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "3")
                                
                UserDefaults.standard.set(["0"], forKey: "selectedFeeds-1");
                
                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;
                
                let mapDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in

                }
                
                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                mapViewController?.mapView?.delegate = mapDelegate
                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(40.0085, -104.2678), animated: false)

            }

            it("two mappable feeds and two non mappable other one selected") {

                MageCoreDataFixtures.populateFeedsFromJson();
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "0")
                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "1")
                
                controller = MageRootViewController(containerScheme: MAGEScheme.scheme());
                window.rootViewController = controller;
                
                let mapDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
                }
                
                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                mapViewController?.mapView?.delegate = mapDelegate
                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(40.0085, -104.2678), animated: false)
                

                UserDefaults.standard.set(["1"], forKey: "selectedFeeds-1");
            }

            it("tap observations button one feed") {

                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed")

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                controller.selectedIndex = 1;

                window.rootViewController = controller;

            }

            it("tap more button one feed") {

                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed")

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;

                tester().tapView(withAccessibilityLabel: "More");
            }

            it("tap more button two feeds") {

                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed")
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2", title: "My Second Feed")
                _ = Feed.mr_findAll();

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;

                tester().tapView(withAccessibilityLabel: "More");
            }
        }
    }
}
