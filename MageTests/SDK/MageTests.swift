//
//  MageTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import PureLayout
import OHHTTPStubs
import Kingfisher

@testable import MAGE

class MageTests: MageCoreDataTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // TODO: Fails
    // BRENT
    func testShouldFetchEvents() async {
        TestHelpers.setupValidToken()
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.currentEventId = 1

        let eventsFetchStubCalled = XCTestExpectation(description: "Events Fetch Called")
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events")
        ) { (request) -> HTTPStubsResponse in
            eventsFetchStubCalled.fulfill();
            let stubPath = OHPathForFile("events.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        let usersFetchStubCalled = XCTestExpectation(description: "Users Fetch Called");
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/myself")
        ) { (request) -> HTTPStubsResponse in
            usersFetchStubCalled.fulfill();
            let stubPath = OHPathForFile("myself.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        let iconsStubCalled = XCTestExpectation(description: "Icon Fetch Called");
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/form/icons.zip")
        ) { (request) -> HTTPStubsResponse in
            iconsStubCalled.fulfill();
            let stubPath = OHPathForFile("plantsAnimalsBuildingsIcons.zip", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/zip"]);
        }
        
        let userIconFetchStubCalled = XCTestExpectation(description: "user Icon Fetch Called");
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/userabc/icon")
        ) { (request) -> HTTPStubsResponse in
            userIconFetchStubCalled.fulfill();
            let stubPath = OHPathForFile("test_marker.png", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        let userAvatarFetchStubCalled = XCTestExpectation(description: "User Avatar Fetch Called");
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/userabc/avatar")
        ) { (request) -> HTTPStubsResponse in
            userAvatarFetchStubCalled.fulfill();
            let stubPath = OHPathForFile("test_marker.png", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        }
        
        let feedsFetchStubCalled = XCTestExpectation(description: "Feeds Fetch Called");
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/feeds")
        ) { (request) -> HTTPStubsResponse in
            feedsFetchStubCalled.fulfill();
            return HTTPStubsResponse(jsonObject:[], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        let featuresFetchStubCalled = XCTestExpectation(description: "Features Fetch Called");
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/layers/44/features")
        ) { (request) -> HTTPStubsResponse in
            featuresFetchStubCalled.fulfill();
            return HTTPStubsResponse(jsonObject:[], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        let mageFormFetchedCalled = XCTestExpectation(description: "Form Fetch Called");
        NotificationCenter.default.addObserver(forName: .MAGEFormFetched, object: nil, queue: nil) { notification in
            mageFormFetchedCalled.fulfill();
        }
        
        MageUseCases.fetchEvents()
        await fulfillment(
            of: [
                usersFetchStubCalled,
                eventsFetchStubCalled,
                iconsStubCalled,
                userIconFetchStubCalled,
                userAvatarFetchStubCalled,
                feedsFetchStubCalled
            ],
            timeout: 2
        )
        
        let sl = context.fetchFirst(StaticLayer.self, key: "eventId", value: 1)
        expect(sl).toNot(beNil())
        
        StaticLayer.fetchStaticLayerData(eventId: 1, staticLayer: sl!)
        
        await fulfillment(
            of: [
                featuresFetchStubCalled,
                mageFormFetchedCalled
            ],
            timeout: 2
        )
    }
}

