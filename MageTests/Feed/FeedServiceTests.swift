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

class FeedServiceTests: MageCoreDataTestCase {
    override open func setUp() {
        super.setUp()
        
        ImageCache.default.clearMemoryCache();
        ImageCache.default.clearDiskCache();

        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.mapType = 0;
        UserDefaults.standard.locationDisplay = .latlng;
        
        Server.setCurrentEventId(1);
        
        MageCoreDataFixtures.addEvent();
    }
    
    override open func tearDown() {
        super.tearDown()
        
        FeedService.shared.stop();
        expect(FeedService.shared.isStopped()).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "Feed Service Stopped");
    }
    
//    override func spec() {
        
//        describe("FeedServiceTests") {
                        
//            beforeEach {
//                ImageCache.default.clearMemoryCache();
//                ImageCache.default.clearDiskCache();
//
//                UserDefaults.standard.baseServerUrl = "https://magetest";
//                UserDefaults.standard.mapType = 0;
//                UserDefaults.standard.locationDisplay = .latlng;
//                
//                Server.setCurrentEventId(1);
//                
//                MageCoreDataFixtures.addEvent();
//            }
//            
//            afterEach {
//                FeedService.shared.stop();
//                expect(FeedService.shared.isStopped()).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "Feed Service Stopped");
//            }
            
    func testShouldRequestFeedItems() {
//            it("should request feed items") {
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")

        var feedItemsServerCallCount = 0;
        MockMageServer.stubJSONSuccessRequest(url: "https://magetest/api/events/1/feeds/1/content", filePath: "feedContent.json")
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api/events/1/feeds/1/content");
        }) { (request) -> HTTPStubsResponse in
            print("in here")
            feedItemsServerCallCount += 1;
            let stubPath = OHPathForFile("feedContent.json", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        };

        FeedService.shared.start();
        expect(feedItemsServerCallCount).toEventually(beGreaterThan(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "Feed Items Pulled");
    }
            
    func testShouldRequestFeedItemsForANewFeed() {
//            it("should request feed items for a new feed") {
                
        var feedItemsServerCallCount = 0;
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api/events/1/feeds/2/content");
        }) { (request) -> HTTPStubsResponse in
            print("returning the feed items")
            feedItemsServerCallCount += 1;
            
            let stubPath = OHPathForFile("feedContent.json", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        };
        FeedService.shared.start();
        
        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "2", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary")
        expect(feedItemsServerCallCount).toEventually(beGreaterThan(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Feed Items Pulled");
    }
}
