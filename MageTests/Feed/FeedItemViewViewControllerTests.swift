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
        
        describe("FeedItemViewController no timestamp") {
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);

            var controller: FeedItemViewController!
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
                let defaults = UserDefaults.standard
                defaults.dictionaryRepresentation().keys.forEach { defaults.removeObject(forKey: $0) }
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            beforeEach {
                ImageCache.default.clearMemoryCache();
                ImageCache.default.clearDiskCache();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/icon.png");
                }) { (request) -> HTTPStubsResponse in
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                };
                
                clearAndSetUpStack();
                
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 414);
                window.autoSetDimension(.height, toSize: 896);
                
                window.makeKeyAndVisible();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                
                Server.setCurrentEventId(1);
                
                MageCoreDataFixtures.addEvent();
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
                HTTPStubs.removeAllStubs();
                clearAndSetUpStack();
            }
            
            it("feed item with no value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: [:])
                var completeTest = false;

                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }

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
            
            it("feed item with no value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: [:])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with no value mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["otherkey": "other value"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary value mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with secondary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with secondary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with secondary value mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value and icon non mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value and icon mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value and icon mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and long secondary value and icon mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi vitae neque et felis mattis congue ut in nisl. Phasellus a massa ipsum. In tempor nisi sit amet erat dignissim blandit. Aenean euismod non urna vel lobortis. Nulla interdum ipsum vel rhoncus efficitur. Aliquam suscipit viverra dui eu facilisis. Pellentesque iaculis, arcu nec porttitor tincidunt, urna ligula auctor nulla, sit amet egestas tortor mi in leo."])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
        
        describe("FeedItemViewController with timestamp") {
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var controller: FeedItemViewController!
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
                let defaults = UserDefaults.standard
                defaults.dictionaryRepresentation().keys.forEach { defaults.removeObject(forKey: $0) }
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            beforeEach {
                ImageCache.default.clearMemoryCache();
                ImageCache.default.clearDiskCache();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/icon.png");
                }) { (request) -> HTTPStubsResponse in
                    let stubPath = OHPathForFile("icon27.png", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                };
                
                clearAndSetUpStack();
                
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 414);
                window.autoSetDimension(.height, toSize: 896);
                
                window.makeKeyAndVisible();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                
                Server.setCurrentEventId(1);
                
                MageCoreDataFixtures.addEvent();
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary", timestampProperty: "timestamp")
            }
            
            afterEach {
                HTTPStubs.removeAllStubs();
                clearAndSetUpStack();
            }
            
            it("feed item with no value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with no value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with no value mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["otherkey": "other value", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary value mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with secondary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with secondary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with secondary value mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["secondary": "secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value non mappable") {
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value mappable") {
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value and icon non mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addNonMappableFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value and icon mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value and icon mappable mgrs") {
                UserDefaults.standard.showMGRS = true;
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "secondary Value for item", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and secondary value and icon without timestamp") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Seconary value for the item"])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
            
            it("feed item with primary and long secondary value and icon mappable") {
                MageCoreDataFixtures.updateStyleForFeed(eventId: 1, id: "1", style: ["iconUrl": "https://magetest/icon.png"])
                MageCoreDataFixtures.addFeedItemToFeed(feedId: "1", properties: ["primary": "Primary Value for item", "secondary": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi vitae neque et felis mattis congue ut in nisl. Phasellus a massa ipsum. In tempor nisi sit amet erat dignissim blandit. Aenean euismod non urna vel lobortis. Nulla interdum ipsum vel rhoncus efficitur. Aliquam suscipit viverra dui eu facilisis. Pellentesque iaculis, arcu nec porttitor tincidunt, urna ligula auctor nulla, sit amet egestas tortor mi in leo.", "timestamp": 1593440445])
                var completeTest = false;
                
                if let feedItem: FeedItem = FeedItem.mr_findFirst() {
                    controller = FeedItemViewController(feedItem: feedItem, scheme: MAGEScheme.scheme())
                    window.rootViewController = controller;
                }
                
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
