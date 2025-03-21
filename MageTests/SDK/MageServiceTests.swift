//
//  MageServiceTests.swift
//  MAGE
//
//  Created by Brent Michalski on 3/20/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation
import Quick
import Nimble
import PureLayout
import OHHTTPStubs
import Kingfisher

@testable import MAGE

class MageServiceTests: AsyncMageCoreDataTestCase {
    @Injected(\.observationPushService)
    var pushService: ObservationPushService
    
    @Injected(\.attachmentPushService)
    var attachmentPushService: AttachmentPushService
    
    override func setUp() async throws {
        try await super.setUp()
        LocationService.singleton().stop();
        LocationFetchService.singleton.stop();
        ObservationFetchService.singleton.stop();
        await pushService.stop();
        attachmentPushService.stop();
        TestHelpers.setupValidToken()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        LocationService.singleton().stop();
        LocationFetchService.singleton.stop();
        ObservationFetchService.singleton.stop();
        await pushService.stop();
        attachmentPushService.stop();
    }
    
//    func testShouldStartServicesAsInitial() async {
//        UserDefaults.standard.baseServerUrl = "https://magetest";
//        UserDefaults.standard.currentEventId = 1
//        MageCoreDataFixtures.addEvent();
//        var started = await pushService.started
//        expect(started).to(beFalse());
//        expect(LocationService.singleton().started).to(beFalse());
//        expect(LocationFetchService.singleton.started).to(beFalse());
//        expect(ObservationFetchService.singleton.started).to(beFalse());
//        expect(self.attachmentPushService.started).to(beFalse());
//        
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications();
//        
//        var mapSettingsFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/settings/map")
//        ) { (request) -> HTTPStubsResponse in
//            mapSettingsFetchStubCalled = true;
//            let stubPath = OHPathForFile("settingsMap.json", MageServiceTests.self);
//            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        var rolesFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/roles")
//        ) { (request) -> HTTPStubsResponse in
//            rolesFetchStubCalled = true;
//            let stubPath = OHPathForFile("roles.json", MageServiceTests.self);
//            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        var usersFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/users")
//        ) { (request) -> HTTPStubsResponse in
//            usersFetchStubCalled = true;
//            let stubPath = OHPathForFile("users.json", MageServiceTests.self);
//            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        var observationsFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/events/1/observations")
//        ) { (request) -> HTTPStubsResponse in
//            observationsFetchStubCalled = true;
//            return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        var locationsFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/events/1/locations/users") &&
//             containsQueryParams(["limit": "1"])
//        ) { (request) -> HTTPStubsResponse in
//            locationsFetchStubCalled = true;
//            return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        Mage.singleton.startServices(initial: true);
//                  
//        await awaitBlockTrue {
//            return mapSettingsFetchStubCalled == true &&
//            rolesFetchStubCalled == true &&
//            usersFetchStubCalled == true &&
//            observationsFetchStubCalled == true &&
//            locationsFetchStubCalled == true
//        }
//        started = await pushService.started
//        expect(started).to(beTrue());
//        
//        await awaitBlockTrue {
//            return ObservationFetchService.singleton.started == true &&
//            self.attachmentPushService.started == true &&
//            LocationService.singleton().started == true &&
//            LocationFetchService.singleton.started == true
//        }
//    }
           
//    @MainActor
//    func testShouldStartServicesAndThenStop() async {
//        UserDefaults.standard.baseServerUrl = "https://magetest";
//        UserDefaults.standard.currentEventId = 1
//        MageCoreDataFixtures.addEvent();
//        var started = await pushService.started
//        expect(started).to(beFalse());
//        expect(LocationService.singleton().started).to(beFalse());
//        expect(LocationFetchService.singleton.started).to(beFalse());
//        expect(ObservationFetchService.singleton.started).to(beFalse());
//        expect(self.attachmentPushService.started).to(beFalse());
//        
//        var mapSettingsFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/settings/map")
//        ) { (request) -> HTTPStubsResponse in
//            mapSettingsFetchStubCalled = true;
//            let stubPath = OHPathForFile("settingsMap.json", MageServiceTests.self);
//            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        var rolesFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/roles")
//        ) { (request) -> HTTPStubsResponse in
//            rolesFetchStubCalled = true;
//            let stubPath = OHPathForFile("roles.json", MageServiceTests.self);
//            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        var usersFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/users")
//        ) { (request) -> HTTPStubsResponse in
//            usersFetchStubCalled = true;
//            let stubPath = OHPathForFile("users.json", MageServiceTests.self);
//            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        var observationsFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/events/1/observations")
//        ) { (request) -> HTTPStubsResponse in
//            observationsFetchStubCalled = true;
//            return HTTPStubsResponse(jsonObject:[], statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        var locationsFetchStubCalled = false;
//        stub(condition: isMethodGET() &&
//             isHost("magetest") &&
//             isScheme("https") &&
//             isPath("/api/events/1/locations/users") &&
//             containsQueryParams(["limit": "1"])
//        ) { (request) -> HTTPStubsResponse in
//            locationsFetchStubCalled = true;
//            return HTTPStubsResponse(jsonObject:[], statusCode: 200, headers: ["Content-Type": "application/json"]);
//        }
//        
//        Mage.singleton.startServices(initial: false);
//        
//        await awaitBlockTrue {
//            return mapSettingsFetchStubCalled == true &&
//            rolesFetchStubCalled == true &&
//            usersFetchStubCalled == true &&
//            observationsFetchStubCalled == true &&
//            locationsFetchStubCalled == true
//        }
//        started = await pushService.started
//        expect(started).to(beTrue());
//        
//        await awaitBlockTrue {
//            return ObservationFetchService.singleton.started == true &&
//            self.attachmentPushService.started == true &&
//            LocationService.singleton().started == true &&
//            LocationFetchService.singleton.started == true
//        }
//        Mage.singleton.stopServices();
//        
//        started = await pushService.started
//        expect(started).to(beFalse())
//        // Location Service does not stop when all services are stopped
//        await awaitBlockTrue {
//            LocationService.singleton().started == true &&
//            LocationFetchService.singleton.started == false &&
//            ObservationFetchService.singleton.started == false &&
//            self.attachmentPushService.started == false
//        }
//    }
}
