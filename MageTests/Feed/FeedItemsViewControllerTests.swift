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
//import Nimble_Snapshots
import PureLayout
import OHHTTPStubs
import Kingfisher

@testable import MAGE

class FeedItemsViewControllerNoTimestampTests: AsyncMageCoreDataTestCase {
    let recordSnapshots = false;
    var controller: FeedItemsViewController!
    var window: UIWindow!;
    
    override open func setUp() async throws {
        try await super.setUp()
        await setupController()
        
        ImageCache.default.clearMemoryCache();
        ImageCache.default.clearDiskCache();
        
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/icon.png");
        }) { (request) -> HTTPStubsResponse in
            let stubPath = OHPathForFile("icon27.png", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        };
                                    
        UserDefaults.standard.mapType = 0;
        UserDefaults.standard.locationDisplay = .latlng;
        Server.setCurrentEventId(1);
        
        MageCoreDataFixtures.addEvent();
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary");
    }
    
    override open func tearDown() async throws {
        try await super.tearDown()
        await tearDownController()
    }
    
    @MainActor
    func setupController() {
        window = TestHelpers.getKeyWindowVisible()
        window.rootViewController = nil;
        controller = nil;
    }
    
    @MainActor
    func tearDownController() {
        controller.dismiss(animated: false, completion: nil);
        window.rootViewController = nil;
        controller = nil;
    }

//    override func spec() {
//        
//        describe("FeedItemsViewController no timestamp") {

                
            
//                afterEach {
//                    controller.dismiss(animated: false, completion: nil);
//                    window.rootViewController = nil;
//                    controller = nil;
//                }
//            
//                beforeEach {
//                    ImageCache.default.clearMemoryCache();
//                    ImageCache.default.clearDiskCache();
//                    
//                    HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
//                        return request.url == URL(string: "https://magetest/icon.png");
//                    }) { (request) -> HTTPStubsResponse in
//                        let stubPath = OHPathForFile("icon27.png", type(of: self))
//                        return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
//                    };
//                    
//                    window = TestHelpers.getKeyWindowVisible();
//                                        
//                    UserDefaults.standard.mapType = 0;
//                    UserDefaults.standard.locationDisplay = .latlng;
//                    Server.setCurrentEventId(1);
//                    
//                    MageCoreDataFixtures.addEvent();
//                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary");
//                }
                
    func testEmptyFeed() {
//                it("empty feed") {
        if let feed: Feed = try? context.fetchFirst(Feed.self) {
        
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail()
        }
    }
                
    func testOneFeedItemWithPrimaryValue() {
//                it("one feed item with primary value") {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                            
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail()
        }
    }
                
    func testOneFeedItemWithSecondaryValue() {
//                it("one feed item with secondary value") {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "Secondary Value for item"])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
                
    func testOneFeedItemWithPrimaryAndSecondaryValue() {
//                it("one feed item with primary and secondary value") {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
                
    func testOneFeedItemWithPrimaryAndSecondaryValueAndIcon() {
//                it("one feed item with primary and secondary value and icon") {
        MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
        
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
                
    func testOneFeedItemNoContent() {
//                it("one feed item no content") {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["notprimary": "Primary Value for item", "notsecondary": "Seconary value for the item"])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
            
}
        

class FeedItemsViewControllerWithTimestampTests: AsyncMageCoreDataTestCase {
    let recordSnapshots = false;
    var controller: FeedItemsViewController!
    var window: UIWindow!;
    
    override open func setUp() async throws {
        try await super.setUp()
        await setupController()
        
        ImageCache.default.clearMemoryCache();
        ImageCache.default.clearDiskCache();
        
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/icon.png");
        }) { (request) -> HTTPStubsResponse in
            let stubPath = OHPathForFile("icon27.png", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        };
                                
        UserDefaults.standard.mapType = 0;
        UserDefaults.standard.locationDisplay = .latlng;
        Server.setCurrentEventId(1);
        
        MageCoreDataFixtures.addEvent();
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary", timestampProperty: "timestamp")
    }
    
    override open func tearDown() async throws {
        try await super.tearDown()
        await tearDownController()
    }
    
    @MainActor
    func setupController() {
        window = TestHelpers.getKeyWindowVisible()
        window.rootViewController = nil;
        controller = nil;
    }
    
    @MainActor
    func tearDownController() {
        window?.rootViewController?.dismiss(animated: false)
        window?.rootViewController = nil
        controller = nil
    }
//        describe("FeedItemsViewController with timestamp") {
//            
//            var controller: FeedItemsViewController!
//            var window: UIWindow!;
//            
//            afterEach {
//                controller.dismiss(animated: false, completion: nil);
//                window.rootViewController = nil;
//                controller = nil;
//            }
//            
//            beforeEach {
//                ImageCache.default.clearMemoryCache();
//                ImageCache.default.clearDiskCache();
//                
//                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
//                    return request.url == URL(string: "https://magetest/icon.png");
//                }) { (request) -> HTTPStubsResponse in
//                    let stubPath = OHPathForFile("icon27.png", type(of: self))
//                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
//                };
//                
//                window = TestHelpers.getKeyWindowVisible();
//                                
//                UserDefaults.standard.mapType = 0;
//                UserDefaults.standard.locationDisplay = .latlng;
//                Server.setCurrentEventId(1);
//                
//                MageCoreDataFixtures.addEvent();
//                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary", timestampProperty: "timestamp")
//            }
            
    func testEmptyFeed() {
//            it("empty feed") {
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }

    }
            
    func testOneFeedItemWithPrimaryValue() {
//            it("one feed item with primary value") {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
            
    func testOneFeedItemWithSecondaryValue() {
//            it("one feed item with secondary value") {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "Secondary Value for item", "timestamp": 1593440445])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
            
    func testOneFeedItemWithPrimaryAndSecondaryValue() {
//            it("one feed item with primary and secondary value") {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }

    }
            
    func testOneFeedItemWithPrimaryAndSecondaryValueAndIcon() {
//            it("one feed item with primary and secondary value and icon") {
        MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
            
    func testOneFeedItemWithPrimaryAndSecondaryValueAndIconWithoutTimestamp() {
//            it("one feed item with primary and secondary value and icon without timestamp") {
        MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
            
    func testOneFeedItemNoContent() {
//            it("one feed item no content") {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["notprimary": "Primary Value for item", "notsecondary": "Seconary value for the item", "timestamp": 1593440445])
                        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail()
        }
    }
}
