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
import PureLayout
import OHHTTPStubs
import Kingfisher

@testable import MAGE

@available(iOS 13.0, *)
class FeedItemViewViewControllerTests: KIFSpec {
    
    override func spec() {
        
        describe("FeedItemViewController no timestamp") {
            var controller: FeedItemViewController!
            var window: UIWindow!;
            
            beforeEach {
                ImageCache.default.clearMemoryCache();
                ImageCache.default.clearDiskCache();
                
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/api/icons/abcdefg/content");
                }) { (request) -> HTTPStubsResponse in
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                };
                
                TestHelpers.clearAndSetUpStack();
                
                window = TestHelpers.getKeyWindowVisible();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                Server.setCurrentEventId(1);
                
                MageCoreDataFixtures.addEvent();
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
            }
            
            it("feed item with no value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: [:])

                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with no value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: [:])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with no value mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["otherkey": "other value"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary value mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with secondary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }

            }
            
            it("feed item with secondary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with secondary value mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and secondary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and secondary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and secondary value mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and secondary value and icon non mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and secondary value and icon mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and secondary value and icon mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and long secondary value and icon mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi vitae neque et felis mattis congue ut in nisl. Phasellus a massa ipsum. In tempor nisi sit amet erat dignissim blandit. Aenean euismod non urna vel lobortis. Nulla interdum ipsum vel rhoncus efficitur. Aliquam suscipit viverra dui eu facilisis. Pellentesque iaculis, arcu nec porttitor tincidunt, urna ligula auctor nulla, sit amet egestas tortor mi in leo."])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
        }
        
        describe("FeedItemViewController with timestamp") {
            var controller: FeedItemViewController!
            var window: UIWindow!;
                
            beforeEach {
                ImageCache.default.clearMemoryCache();
                ImageCache.default.clearDiskCache();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/icon.png");
                }) { (request) -> HTTPStubsResponse in
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                };
                
                TestHelpers.clearAndSetUpStack();

                window = TestHelpers.getKeyWindowVisible();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                
                Server.setCurrentEventId(1);
                
                MageCoreDataFixtures.addEvent();
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary", timestampProperty: "timestamp")
            }
            
            afterEach {
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
            }
            
            it("feed item with no value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with no value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }

            }
            
            it("feed item with no value mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["otherkey": "other value", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }

            }
            
            it("feed item with primary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary value mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with secondary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with secondary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with secondary value mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and secondary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and secondary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }

            }
            
            it("feed item with primary and secondary value mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }

            }
            
            it("feed item with primary and secondary value and icon non mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }

            }
            
            it("feed item with primary and secondary value and icon mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style:["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }

            }
            
            it("feed item with primary and secondary value and icon mappable mgrs") {
                UserDefaults.standard.locationDisplay = .mgrs;
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and secondary value and icon without timestamp") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
            
            it("feed item with primary and long secondary value and icon mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["icon": ["id": "abcdefg"]])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi vitae neque et felis mattis congue ut in nisl. Phasellus a massa ipsum. In tempor nisi sit amet erat dignissim blandit. Aenean euismod non urna vel lobortis. Nulla interdum ipsum vel rhoncus efficitur. Aliquam suscipit viverra dui eu facilisis. Pellentesque iaculis, arcu nec porttitor tincidunt, urna ligula auctor nulla, sit amet egestas tortor mi in leo.", "timestamp": 1593440445])
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
            }
        }
    }
}
