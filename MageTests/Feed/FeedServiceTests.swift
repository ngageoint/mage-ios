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

                    UserDefaults.standard.set("https://magetest", forKey: "baseServerUrl");
                    UserDefaults.standard.set(0, forKey: "mapType");
                    UserDefaults.standard.set(false, forKey: "showMGRS");
                    UserDefaults.standard.synchronize();
                    
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
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: 1, title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                        done();
                    }
                }

                var feedItemsServerCallCount = 0;
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    print("pass test request", request);
                    print("does it pass?", request.url == URL(string: "https://magetest/api/events/1/feeds/1/items"));
                    return request.url == URL(string: "https://magetest/api/events/1/feeds/1/items");
                }) { (request) -> HTTPStubsResponse in
                    feedItemsServerCallCount += 1;

                    let stubPath = OHPathForFile("feed1Items.json", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                };
                FeedService.shared.start();
//                DispatchQueue.global(qos: .userInitiated).async {
//                    Thread.sleep(forTimeInterval: 1.0);
//                    DispatchQueue.main.async {
                        expect(feedItemsServerCallCount).toEventually(equal(1), timeout: 10, pollInterval: 1, description: "Feed Items Pulled");
//                    }
//                }
            }
            
            it("should request feed items for a new feed") {
                
                var feedItemsServerCallCount = 0;
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    print("pass test request2", request);
                    print("does it pass2?", request.url == URL(string: "https://magetest/api/events/1/feeds/1/items"));
                    return request.url == URL(string: "https://magetest/api/events/1/feeds/1/items");
                }) { (request) -> HTTPStubsResponse in
                    
                    feedItemsServerCallCount += 1;
                    
                    let stubPath = OHPathForFile("feed1Items.json", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                };
                FeedService.shared.start();
                
                MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: 1, title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                    print("Added the feed");
                }
                expect(feedItemsServerCallCount).toEventually(equal(1), timeout: 10, pollInterval: 1, description: "Feed Items Pulled");
            }
        }
    }
}
