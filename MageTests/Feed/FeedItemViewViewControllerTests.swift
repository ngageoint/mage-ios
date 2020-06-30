//
//  FeedItemViewViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/18/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import PureLayout
import OHHTTPStubs
import Kingfisher

@testable import MAGE

@available(iOS 13.0, *)
class FeedItemViewViewControllerTests: KIFSpec {
    
    override func spec() {
        
        describe("FeedItemViewViewController") {
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);

            var controller: FeedItemViewViewController!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 1.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot();
                            doneClosure?();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
            func clearAndSetUpStack() {
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            beforeEach {
                ImageCache.default.clearMemoryCache();
                ImageCache.default.clearDiskCache();
                
                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.set(false, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
                
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/icon.png");
                }) { (request) -> HTTPStubsResponse in
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                };
                
                waitUntil { done in
                    clearAndSetUpStack();
                    
                    window = UIWindow(forAutoLayout: ());
                    window.autoSetDimension(.width, toSize: 414);
                    window.autoSetDimension(.height, toSize: 896);
                    
                    window.makeKeyAndVisible();
                    
                    UserDefaults.standard.set(0, forKey: "mapType");
                    UserDefaults.standard.set(false, forKey: "showMGRS");
                    UserDefaults.standard.synchronize();
                    
                    Server.setCurrentEventId(1);
                    
                    MageCoreDataFixtures.addEvent { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: 1, title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }
            }
            
            afterEach {
                HTTPStubs.removeAllStubs();
                clearAndSetUpStack();
            }
            
            it("one feed item with no value non mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: 1, properties: [:]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with no value mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: [: ]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with no value mappable mgrs") {
                UserDefaults.standard.set(true, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["otherkey": "other value"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with primary value non mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with primary value mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with primary value mappable mgrs") {
                UserDefaults.standard.set(true, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with secondary value non mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: 1, properties: ["secondary": "secondary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with secondary value mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["secondary": "secondary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with secondary value mappable mgrs") {
                UserDefaults.standard.set(true, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["secondary": "secondary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with primary and secondary value non mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with primary and secondary value mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with primary and secondary value mappable mgrs") {
                UserDefaults.standard.set(true, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
                waitUntil { done in
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"]) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with primary and secondary value and icon non mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: 1, style: ["iconUrl": "https://magetest/icon.png"])  { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"]) { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with primary and secondary value and icon mappable") {
                waitUntil { done in
                    MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: 1, style: ["iconUrl": "https://magetest/icon.png"])  { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"]) { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed item with primary and secondary value and icon mappable mgrs") {
                UserDefaults.standard.set(true, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
                waitUntil { done in
                    MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: 1, style: ["iconUrl": "https://magetest/icon.png"])  { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"]) { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewViewController(feedItem: feedItem)
                    window.rootViewController = controller;
                }
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
//            it("one feed item with secondary value") {
//                waitUntil { done in
//                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["secondary": "Secondary Value for item"]) { (success: Bool, error: Error?) in
//                        done();
//                    }
//                }
//                var completeTest = false;
//
//                if let feed: Feed = Feed.mr_findFirst() {
//                    controller = FeedItemsViewController(feed: feed);
//                    window.rootViewController = controller;
//                }
//
//                maybeRecordSnapshot(controller.view, doneClosure: {
//                    completeTest = true;
//                })
//
//                if (recordSnapshots) {
//                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
//                } else {
//                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
//                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
//                }
//            }
//
//            it("one feed item with primary and secondary value") {
//                waitUntil { done in
//                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"]) { (success: Bool, error: Error?) in
//                        done();
//                    }
//                }
//                var completeTest = false;
//
//                if let feed: Feed = Feed.mr_findFirst() {
//                    controller = FeedItemsViewController(feed: feed);
//                    window.rootViewController = controller;
//                }
//
//                maybeRecordSnapshot(controller.view, doneClosure: {
//                    completeTest = true;
//                })
//
//                if (recordSnapshots) {
//                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
//                } else {
//                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
//                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
//                }
//            }
//
//            it("one feed item with primary and secondary value and icon") {
//                waitUntil { done in
//                    MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: 1, style: ["iconUrl": "https://magetest/icon.png"])  { (success: Bool, error: Error?) in
//                        MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"]) { (success: Bool, error: Error?) in
//                            done();
//                        }
//                    }
//                }
//                var completeTest = false;
//
//                if let feed: Feed = Feed.mr_findFirst() {
//                    controller = FeedItemsViewController(feed: feed);
//                    window.rootViewController = controller;
//                }
//
//                maybeRecordSnapshot(controller.view, doneClosure: {
//                    completeTest = true;
//                })
//
//                if (recordSnapshots) {
//                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
//                } else {
//                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
//                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
//                }
//            }
//
//            it("one feed item no content") {
//                waitUntil { done in
//                    MageCoreDataFixtures.addFeedItemToFeed(feedId: 1, properties: ["notprimary": "Primary Value for item", "notsecondary": "Seconary value for the item"]) { (success: Bool, error: Error?) in
//                        done();
//                    }
//                }
//                var completeTest = false;
//
//                if let feed: Feed = Feed.mr_findFirst() {
//                    controller = FeedItemsViewController(feed: feed);
//                    window.rootViewController = controller;
//                }
//
//                maybeRecordSnapshot(controller.view, doneClosure: {
//                    completeTest = true;
//                })
//
//                if (recordSnapshots) {
//                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
//                } else {
//                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
//                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
//                }
//            }
        }
    }
}
