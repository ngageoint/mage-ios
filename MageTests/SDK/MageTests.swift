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

class MageServiceTests: MageCoreDataTestCase {
    
    override func setUp() {
        super.setUp()
        LocationService.singleton().stop();
        LocationFetchService.singleton.stop();
        ObservationFetchService.singleton.stop();
        ObservationPushService.singleton.stop();
        AttachmentPushService.singleton().stop();
        TestHelpers.setupValidToken()
    }
    
    override func tearDown() {
        super.tearDown()
        LocationService.singleton().stop();
        LocationFetchService.singleton.stop();
        ObservationFetchService.singleton.stop();
        ObservationPushService.singleton.stop();
        AttachmentPushService.singleton().stop();
    }
    
    func testShouldStartServicesAsInitial() {
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.currentEventId = 1
        MageCoreDataFixtures.addEvent(context: context!);
        expect(ObservationPushService.singleton.started).to(beFalse());
        expect(LocationService.singleton().started).to(beFalse());
        expect(LocationFetchService.singleton.started).to(beFalse());
        expect(ObservationFetchService.singleton.started).to(beFalse());
        expect(AttachmentPushService.singleton().started).to(beFalse());
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications();
        
        var mapSettingsFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/settings/map")
        ) { (request) -> HTTPStubsResponse in
            mapSettingsFetchStubCalled = true;
            let stubPath = OHPathForFile("settingsMap.json", MageServiceTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var rolesFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/roles")
        ) { (request) -> HTTPStubsResponse in
            rolesFetchStubCalled = true;
            let stubPath = OHPathForFile("roles.json", MageServiceTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var usersFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users")
        ) { (request) -> HTTPStubsResponse in
            usersFetchStubCalled = true;
            let stubPath = OHPathForFile("users.json", MageServiceTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var observationsFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/observations")
        ) { (request) -> HTTPStubsResponse in
            observationsFetchStubCalled = true;
            return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var locationsFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/locations/users") &&
             containsQueryParams(["limit": "1"])
        ) { (request) -> HTTPStubsResponse in
            locationsFetchStubCalled = true;
            return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        Mage.singleton.startServices(initial: true);
                  
        expect(mapSettingsFetchStubCalled).toEventually(beTrue())
        expect(rolesFetchStubCalled).toEventually(beTrue())
        expect(usersFetchStubCalled).toEventually(beTrue());
        expect(observationsFetchStubCalled).toEventually(beTrue());
        expect(locationsFetchStubCalled).toEventually(beTrue());
        expect(ObservationPushService.singleton.started).toEventually(beTrue());
        expect(ObservationFetchService.singleton.started).toEventually(beTrue());
        expect(AttachmentPushService.singleton().started).toEventually(beTrue());
        expect(LocationService.singleton().started).to(beTrue());
        expect(LocationFetchService.singleton.started).to(beTrue());
    }
            
    func testShouldStartServicesAndThenStop() {
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.currentEventId = 1
        MageCoreDataFixtures.addEvent(context: context);
        expect(ObservationPushService.singleton.started).to(beFalse());
        expect(LocationService.singleton().started).to(beFalse());
        expect(LocationFetchService.singleton.started).to(beFalse());
        expect(ObservationFetchService.singleton.started).to(beFalse());
        expect(AttachmentPushService.singleton().started).to(beFalse());
        
        var mapSettingsFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/settings/map")
        ) { (request) -> HTTPStubsResponse in
            mapSettingsFetchStubCalled = true;
            let stubPath = OHPathForFile("settingsMap.json", MageServiceTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var rolesFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/roles")
        ) { (request) -> HTTPStubsResponse in
            rolesFetchStubCalled = true;
            let stubPath = OHPathForFile("roles.json", MageServiceTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var usersFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users")
        ) { (request) -> HTTPStubsResponse in
            usersFetchStubCalled = true;
            let stubPath = OHPathForFile("users.json", MageServiceTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var observationsFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/observations")
        ) { (request) -> HTTPStubsResponse in
            observationsFetchStubCalled = true;
            return HTTPStubsResponse(jsonObject:[], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        var locationsFetchStubCalled = false;
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/locations/users") &&
             containsQueryParams(["limit": "1"])
        ) { (request) -> HTTPStubsResponse in
            locationsFetchStubCalled = true;
            return HTTPStubsResponse(jsonObject:[], statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        Mage.singleton.startServices(initial: false);
        
        expect(mapSettingsFetchStubCalled).toEventually(beTrue())
        expect(rolesFetchStubCalled).toEventually(beTrue())
        expect(usersFetchStubCalled).toEventually(beTrue());
        expect(observationsFetchStubCalled).toEventually(beTrue());
        expect(locationsFetchStubCalled).toEventually(beTrue());
        expect(ObservationPushService.singleton.started).toEventually(beTrue());
        expect(ObservationFetchService.singleton.started).toEventually(beTrue());
        expect(AttachmentPushService.singleton().started).toEventually(beTrue());
        expect(LocationService.singleton().started).to(beTrue());
        expect(LocationFetchService.singleton.started).to(beTrue());
        
        Mage.singleton.stopServices();
        
        expect(ObservationPushService.singleton.started).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Observation Push Service still running")
        // Location Service does not stop when all services are stopped
        expect(LocationService.singleton().started).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Location Service still running")
        expect(LocationFetchService.singleton.started).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Location Fetch Service still running")
        expect(ObservationFetchService.singleton.started).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Observation Fetch Service still running")
        expect(AttachmentPushService.singleton().started).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Attachment Push Service still running")
    }
}
