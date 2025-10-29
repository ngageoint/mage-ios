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
import PureLayout
import OHHTTPStubs
import Kingfisher

@testable import MAGE

// TODO: These tests are flaky
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

    func testEmptyFeed() {
        if let feed: Feed = try? context.fetchFirst(Feed.self) {
        
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail()
        }
    }
                
    // TODO: FLAKY Test, causes CRASH
    // BRENT: Here is the error thrown in the test
    /// UITableViewDiffableDataSource cell provider returned nil for index path <NSIndexPath: 0xbdd6ae0311845a50> {length = 2, path = 0 - 0} with item identifier '0xbdd6ae0311a44625 <x-coredata://52EDFE6D-5413-4FD7-9821-F0D60C2E9782/FeedItem/p1>', which is not allowed. You must always return a cell to the table view: <UITableView: 0x49fdd5800; frame = (0 0; 440 956); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x600004fabae0>; backgroundColor = <UIDynamicCatalogColor: 0x60000a10b340; name = background>; layer = <CALayer: 0x6000046bbfa0>; contentOffset: {0, -62}; contentSize: {440, 144.33333333333331}; adjustedContentInset: {62, 0, 34, 0}; dataSource: <_TtGC5UIKit29UITableViewDiffableDataSourceSiCSo17NSManagedObjectID_: 0x600004106110>> (NSInternalInconsistencyException)
    
    func testOneFeedItemWithPrimaryValue() {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                            
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail()
        }
    }
                
    func testOneFeedItemWithSecondaryValue() {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "Secondary Value for item"])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
                
    func testOneFeedItemWithPrimaryAndSecondaryValue() {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
              
    // TODO: Failing test
    func testOneFeedItemWithPrimaryAndSecondaryValueAndIcon() {
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

    func testEmptyFeed() {
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }

    }
            
    // TODO: Another flaky test.
    func testOneFeedItemWithPrimaryValue() {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
            
    func testOneFeedItemWithSecondaryValue() {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "Secondary Value for item", "timestamp": 1593440445])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
            
    func testOneFeedItemWithPrimaryAndSecondaryValue() {
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }

    }
            
    func testOneFeedItemWithPrimaryAndSecondaryValueAndIcon() {
        MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])
        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail();
        }
    }
            
    // TODO: Failing
    func testOneFeedItemWithPrimaryAndSecondaryValueAndIconWithoutTimestamp() {
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
        MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["notprimary": "Primary Value for item", "notsecondary": "Seconary value for the item", "timestamp": 1593440445])
                        
        if let feed: Feed = Feed.mr_findFirst() {
            controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
            window.rootViewController = controller;
        } else {
            Nimble.fail()
        }
    }
}
