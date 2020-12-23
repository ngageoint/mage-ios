//
//  FeedServiceTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/17/20.
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
class FeedServiceTests: KIFSpec {
    
    override func spec() {
        
        describe("FeedServiceTests") {
            
            func clearAndSetUpStack() {
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            beforeEach {
                ImageCache.default.clearMemoryCache();
                ImageCache.default.clearDiskCache();
                
                waitUntil { done in
                    clearAndSetUpStack();
                    MageCoreDataFixtures.quietLogging();

                    UserDefaults.standard.baseServerUrl = "https://magetest";
                    UserDefaults.standard.mapType = 0;
                    UserDefaults.standard.showMGRS = false;
                    
                    Server.setCurrentEventId(1);
                    
                    MageCoreDataFixtures.addEvent { (success: Bool, error: Error?) in
                        done();
                    }
                }
            }
            
            afterEach {
                FeedService.shared.stop();
                HTTPStubs.removeAllStubs();
                clearAndSetUpStack();
            }
            
            it("should request feed items") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                        done();
                    }
                }

                var feedItemsServerCallCount = 0;
                MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api/events/1/feeds/1/content", filePath: "feedContent.json")
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/api/events/1/feeds/1/content");
                }) { (request) -> HTTPStubsResponse in
                    feedItemsServerCallCount += 1;
                    let stubPath = OHPathForFile("feedContent.json", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                };

                FeedService.shared.start();
                expect(feedItemsServerCallCount).toEventually(beGreaterThan(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "Feed Items Pulled");
            }
            
            it("should request feed items for a new feed") {
                
                var feedItemsServerCallCount = 0;
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/api/events/1/feeds/1/content");
                }) { (request) -> HTTPStubsResponse in
                    
                    feedItemsServerCallCount += 1;
                    
                    let stubPath = OHPathForFile("feedContent.json", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                };
                FeedService.shared.start();
                
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                    print("Added the feed");
                }
                expect(feedItemsServerCallCount).toEventually(beGreaterThan(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Feed Items Pulled");
            }
        }
    }
}
