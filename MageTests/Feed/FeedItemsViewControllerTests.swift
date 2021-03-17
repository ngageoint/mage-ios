//
//  FeedItemsViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/11/20.
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
class FeedItemsViewControllerTests: KIFSpec {
    let recordSnapshots = false;

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
    
    override func spec() {
        
        describe("FeedItemsViewController no timestamp") {
            Nimble_Snapshots.setNimbleTolerance(0);
                
                func clearAndSetUpStack() {
                    MageInitializer.initializePreferences();
                    MageInitializer.clearAndSetupCoreData();
                }
                
                var controller: FeedItemsViewController!
                var window: UIWindow!;
            
                afterEach {
                    controller.dismiss(animated: false, completion: nil);
                    window.rootViewController = nil;
                    controller = nil;
                    HTTPStubs.removeAllStubs();
                    clearAndSetUpStack();
                }
            
                beforeEach {
                    ImageCache.default.clearMemoryCache();
                    ImageCache.default.clearDiskCache();
                    
                    HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                        return request.url == URL(string: "https://magetest/icon.png");
                    }) { (request) -> HTTPStubsResponse in
                        let stubPath = OHPathForFile("icon27.png", type(of: self))
                        return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    };
                    
                    window = UIWindow(forAutoLayout: ());
                    window.autoSetDimension(.width, toSize: 414);
                    window.autoSetDimension(.height, toSize: 896);
                    
                    window.makeKeyAndVisible();
                    
                    clearAndSetUpStack();
                    
                    UserDefaults.standard.mapType = 0;
                    UserDefaults.standard.showMGRS = false;
                    Server.setCurrentEventId(1);
                    
                    MageCoreDataFixtures.addEvent();
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary");
                }
                
                it("empty feed") {
                    
                    var completeTest = false;
                    
                    let feed: Feed = Feed.mr_findFirst()!
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                    
                    self.maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })

                    if (self.recordSnapshots) {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    } else {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                        expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                    }
                }
                
                it("one feed item with primary value") {
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                    
                    var completeTest = false;
                    
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    }
                    
                    self.maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                    
                    if (self.recordSnapshots) {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    } else {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                        expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                    }
                }
                
                it("one feed item with secondary value") {
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "Secondary Value for item"])
                    var completeTest = false;
                    
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    }
                    
                    self.maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                    
                    if (self.recordSnapshots) {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    } else {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                        expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                    }
                }
                
                it("one feed item with primary and secondary value") {
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
                    var completeTest = false;
                    
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    }
                    
                    self.maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                    
                    if (self.recordSnapshots) {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    } else {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                        expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                    }
                }
                
                it("one feed item with primary and secondary value and icon") {
                    MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
                    
                    var completeTest = false;
                    
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    }
                    
                    self.maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                    
                    if (self.recordSnapshots) {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    } else {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                        expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                    }
                }
                
                it("one feed item no content") {
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["notprimary": "Primary Value for item", "notsecondary": "Seconary value for the item"])
                    var completeTest = false;
                    
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    }
                    
                    self.maybeRecordSnapshot(controller.view, doneClosure: {
                        completeTest = true;
                    })
                    
                    if (self.recordSnapshots) {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    } else {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                        expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                    }
                }
            
        }
        
        describe("FeedItemsViewController with timestamp") {
            Nimble_Snapshots.setNimbleTolerance(0);

            func clearAndSetUpStack() {
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            afterEach {
                HTTPStubs.removeAllStubs();
                clearAndSetUpStack();
            }
            
            var controller: FeedItemsViewController!
            var window: UIWindow!;
            
            beforeEach {
                ImageCache.default.clearMemoryCache();
                ImageCache.default.clearDiskCache();
                
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/icon.png");
                }) { (request) -> HTTPStubsResponse in
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                };
                
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 414);
                window.autoSetDimension(.height, toSize: 896);
                
                window.makeKeyAndVisible();
                
                clearAndSetUpStack();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                Server.setCurrentEventId(1);
                
                MageCoreDataFixtures.addEvent();
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary", timestampProperty: "timestamp")
            }
            
            it("empty feed") {
                
                var completeTest = false;
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                }
                
                self.maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (self.recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("one feed item with primary value") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                }
                
                self.maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (self.recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("one feed item with secondary value") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "Secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                }
                
                self.maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (self.recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("one feed item with primary and secondary value") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                }
                
                self.maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (self.recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("one feed item with primary and secondary value and icon") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                }
                
                self.maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (self.recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("one feed item with primary and secondary value and icon without timestamp") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
                var completeTest = false;
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                }
                
                self.maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (self.recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("one feed item no content") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["notprimary": "Primary Value for item", "notsecondary": "Seconary value for the item", "timestamp": 1593440445])
                
                var completeTest = false;
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                }
                
                self.maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (self.recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
        }
    }
}
