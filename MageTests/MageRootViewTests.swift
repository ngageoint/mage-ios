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
import Nimble_Snapshots
import PureLayout
import OHHTTPStubs
import XCTest

@testable import MAGE

@available(iOS 13.0, *)
class MageRootViewTests: KIFSpec {
    
    override func spec() {
        
        describe("MageRootView") {
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.01);
            
            var controller: MageRootViewController!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot();
                            doneClosure?();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
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
                waitUntil { done in
                    TestHelpers.clearAndSetUpStack();
                    UserDefaults.standard.baseServerUrl = "https://magetest";
                    
                    stub(condition: isHost("magetest")) { (request) -> HTTPStubsResponse in
                        return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil);
                    };
                    
                    MockMageServer.initializeHttpStubs();
                    window = UIWindow(forAutoLayout: ());
                    window.autoSetDimension(.width, toSize: 414);
                    window.autoSetDimension(.height, toSize: 896);
                    
                    window.makeKeyAndVisible();
                    
                    let domain = Bundle.main.bundleIdentifier!
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    UserDefaults.standard.synchronize()
                    
                    MageCoreDataFixtures.addEvent { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        done();
                    }
                }
            }

            afterEach {
                waitUntil { done in
                    controller.dismiss(animated: false, completion: {
                        window.rootViewController = nil;
                        controller = nil;
                        TestHelpers.clearAndSetUpStack();
                        HTTPStubs.removeAllStubs();
                        done();
                    })
                }
            }
            
            it("no feeds") {
                var completeTest = false;

                let mapDelegate: MockMapViewDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
                    maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                }

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme());
                window.rootViewController = controller;

                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                mapViewController?.mapView?.delegate = mapDelegate
                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(0, 0), animated: false)

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("one feed") {
                var completeTest = false;

                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed") { (success: Bool, error: Error?) in
                        done();
                    }
                }

                let mapDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
                    maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                }

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;

                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                mapViewController?.mapView?.delegate = mapDelegate
                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(0, 0), animated: false)

                window.rootViewController = controller;
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            // when brand new feeds are added, they are automatically enabled
            it("two mappable feeds and two non mappable brand new") {
                var completeTest = false;

                waitUntil { done in
                    MageCoreDataFixtures.populateFeedsFromJson { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "0") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "1") { (success: Bool, error: Error?) in
                                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "2") { (success: Bool, error: Error?) in
                                    MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "3") { (success: Bool, error: Error?) in
                                        done();
                                    }
                                }
                            }
                        }
                    }
                }
                
                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;
                
                let mapDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
                    maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                mapViewController?.mapView?.delegate = mapDelegate
                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(40.0085, -104.2678), animated: false)

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("two mappable feeds and two non mappable one selected") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.populateFeedsFromJson { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "0") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "1") { (success: Bool, error: Error?) in
                                MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "2") { (success: Bool, error: Error?) in
                                    MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "3") { (success: Bool, error: Error?) in
                                        done();
                                    }
                                }
                            }
                        }
                    }
                }
                                
                UserDefaults.standard.set(["0"], forKey: "selectedFeeds-1");
                
                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;
                
                let mapDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
                    maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                mapViewController?.mapView?.delegate = mapDelegate
                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(40.0085, -104.2678), animated: false)

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("two mappable feeds and two non mappable other one selected") {
                var completeTest = false;

                waitUntil { done in
                    MageCoreDataFixtures.populateFeedsFromJson { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "0") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.populateFeedItemsFromJson(feedId: "1") { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                controller = MageRootViewController(containerScheme: MAGEScheme.scheme());
                window.rootViewController = controller;
                
                let mapDelegate = MockMapViewDelegate()
                mapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
                    maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                let mapViewController = (controller.viewControllers?[0] as? UINavigationController)?.viewControllers.first as? MapViewController
                mapViewController?.beginAppearanceTransition(true, animated: false)
                mapViewController?.endAppearanceTransition()
                mapViewController?.mapView?.delegate = mapDelegate
                mapViewController?.mapView.setCenter(CLLocationCoordinate2DMake(40.0085, -104.2678), animated: false)
                

                UserDefaults.standard.set(["1"], forKey: "selectedFeeds-1");

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("tap observations button one feed") {
                var completeTest = false;

                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed") { (success: Bool, error: Error?) in
                        done();
                    }
                }

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                controller.selectedIndex = 1;

                window.rootViewController = controller;
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("tap more button one feed") {
                var completeTest = false;

                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed") { (success: Bool, error: Error?) in
                        done();
                    }
                }

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;

                tester().tapView(withAccessibilityLabel: "More");

                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("tap more button two feeds") {
                var completeTest = false;

                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2", title: "My Second Feed") { (success: Bool, error: Error?) in
                            let feeds = Feed.mr_findAll();
                            print("Feeds \(feeds)")
                            done();
                        }
                    }
                }

                controller = MageRootViewController(containerScheme: MAGEScheme.scheme())
                window.rootViewController = controller;

                tester().tapView(withAccessibilityLabel: "More");

                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
        }
    }
}
