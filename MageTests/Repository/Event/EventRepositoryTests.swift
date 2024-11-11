//
//  EventRepositoryTests.swift
//  MAGETests
//
//  Created by Dan Barela on 9/3/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Combine
import Nimble
import OHHTTPStubs

@testable import MAGE

final class EventRepositoryTests: MageCoreDataTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.baseServerUrl = "https://magetest"
    }
    
    func testFetchEvents() async {
        TestHelpers.setupValidToken()
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/myself")
        ) { (request) -> HTTPStubsResponse in
            let stubPath = OHPathForFile("myself.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events")
        ) { (request) -> HTTPStubsResponse in
            let stubPath = OHPathForFile("threeEvents.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        let user = MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
        UserDefaults.standard.currentUserId = "userabc"
        
        let repository = EventRepositoryImpl()
        await repository.fetchEvents()
        
        let events = context.fetchAll(Event.self)
        
        XCTAssertEqual(events?.count, 3)
        
        Server.setCurrentEventId(1)
        
        let event = context.fetchFirst(Event.self, key: "remoteId", value: 1)
        
        XCTAssertNotNil(event)
        XCTAssertTrue(event!.isUserInEvent(user: user))
    }
}
