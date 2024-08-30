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

@available(iOS 13.0, *)
class FeedItemsViewControllerTests: KIFSpec {
    let recordSnapshots = false;

//    func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
//        print("Record snapshot?", recordSnapshots);
//        if (recordSnapshots || recordThisSnapshot) {
//            DispatchQueue.global(qos: .userInitiated).async {
//                Thread.sleep(forTimeInterval: 1.0);
//                DispatchQueue.main.async {
//                    expect(view) == recordSnapshot();
//                    doneClosure?();
//                }
//            }
//        } else {
//            doneClosure?();
//        }
//    }
    
    override func spec() {
        
        xdescribe("FeedItemsViewController no timestamp") {
//            Nimble_Snapshots.setNimbleTolerance(0);
                
            var coreDataStack: TestCoreDataStack?
            var context: NSManagedObjectContext!
                var controller: FeedItemsViewController!
                var window: UIWindow!;
            
                afterEach {
                    controller.dismiss(animated: false, completion: nil);
                    window.rootViewController = nil;
                    controller = nil;
                    HTTPStubs.removeAllStubs();
                    TestHelpers.clearAndSetUpStack();
                    InjectedValues[\.nsManagedObjectContext] = nil
                    coreDataStack!.reset()
                }
            
                beforeEach {
                    coreDataStack = TestCoreDataStack()
                    context = coreDataStack!.persistentContainer.newBackgroundContext()
                    InjectedValues[\.nsManagedObjectContext] = context
                    ImageCache.default.clearMemoryCache();
                    ImageCache.default.clearDiskCache();
                    
                    HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                        return request.url == URL(string: "https://magetest/icon.png");
                    }) { (request) -> HTTPStubsResponse in
                        let stubPath = OHPathForFile("icon27.png", type(of: self))
                        return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                    };
                    
                    window = TestHelpers.getKeyWindowVisible();
                    
                    TestHelpers.clearAndSetUpStack();
                    
                    UserDefaults.standard.mapType = 0;
                    UserDefaults.standard.locationDisplay = .latlng;
                    Server.setCurrentEventId(1);
                    
                    MageCoreDataFixtures.addEvent(context: context);
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary");
                }
                
                it("empty feed") {
                    if let feed: Feed = Feed.mr_findFirst() {
                    
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    } else {
                        Nimble.fail()
                    }
                }
                
                it("one feed item with primary value") {
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                                        
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    } else {
                        Nimble.fail()
                    }
                }
                
                it("one feed item with secondary value") {
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "Secondary Value for item"])
                    
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    } else {
                        Nimble.fail();
                    }
                }
                
                it("one feed item with primary and secondary value") {
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
                    
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    } else {
                        Nimble.fail();
                    }
                }
                
                it("one feed item with primary and secondary value and icon") {
                    MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
                    
                    
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    } else {
                        Nimble.fail();
                    }
                }
                
                it("one feed item no content") {
                    MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["notprimary": "Primary Value for item", "notsecondary": "Seconary value for the item"])
                    
                    if let feed: Feed = Feed.mr_findFirst() {
                        controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                        window.rootViewController = controller;
                    } else {
                        Nimble.fail();
                    }
                }
            
        }
        
        xdescribe("FeedItemsViewController with timestamp") {
            
            var controller: FeedItemsViewController!
            var window: UIWindow!;
            var coreDataStack: TestCoreDataStack?
            var context: NSManagedObjectContext!
            
            afterEach {
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
                InjectedValues[\.nsManagedObjectContext] = nil
                coreDataStack!.reset()
            }
            beforeEach {
                coreDataStack = TestCoreDataStack()
                context = coreDataStack!.persistentContainer.newBackgroundContext()
                InjectedValues[\.nsManagedObjectContext] = context
                ImageCache.default.clearMemoryCache();
                ImageCache.default.clearDiskCache();
                
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/icon.png");
                }) { (request) -> HTTPStubsResponse in
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                };
                
                window = TestHelpers.getKeyWindowVisible();
                
                TestHelpers.clearAndSetUpStack();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                Server.setCurrentEventId(1);
                
                MageCoreDataFixtures.addEvent(context: context);
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary", timestampProperty: "timestamp")
            }
            
            it("empty feed") {
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                } else {
                    Nimble.fail();
                }

            }
            
            it("one feed item with primary value") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                } else {
                    Nimble.fail();
                }
            }
            
            it("one feed item with secondary value") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "Secondary Value for item", "timestamp": 1593440445])
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                } else {
                    Nimble.fail();
                }
            }
            
            it("one feed item with primary and secondary value") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                } else {
                    Nimble.fail();
                }

            }
            
            it("one feed item with primary and secondary value and icon") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item", "timestamp": 1593440445])
                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                } else {
                    Nimble.fail();
                }
            }
            
            it("one feed item with primary and secondary value and icon without timestamp") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                } else {
                    Nimble.fail();
                }
            }
            
            it("one feed item no content") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["notprimary": "Primary Value for item", "notsecondary": "Seconary value for the item", "timestamp": 1593440445])
                                
                if let feed: Feed = Feed.mr_findFirst() {
                    controller = FeedItemsViewController(feed: feed, scheme: MAGEScheme.scheme());
                    window.rootViewController = controller;
                } else {
                    Nimble.fail()
                }
            }
        }
    }
}
