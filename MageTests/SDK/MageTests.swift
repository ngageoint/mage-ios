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

class MageTests: KIFSpec {
    
    override func spec() {
        
        describe("MageTests") {
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                LocationService.singleton().stop();
                LocationFetchService.singleton().stop();
                ObservationFetchService.singleton.stop();
                ObservationPushService.singleton.stop();
                AttachmentPushService.singleton().stop();
            }
            
            afterEach {
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
                LocationService.singleton().stop();
                LocationFetchService.singleton().stop();
                ObservationFetchService.singleton.stop();
                ObservationPushService.singleton.stop();
                AttachmentPushService.singleton().stop();
            }
            
            it("should start services as initial") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                MageCoreDataFixtures.addEvent();
                expect(ObservationPushService.singleton.started).to(beFalse());
                expect(LocationService.singleton().started).to(beFalse());
                expect(LocationFetchService.singleton().started).to(beFalse());
                expect(ObservationFetchService.singleton.started).to(beFalse());
                expect(AttachmentPushService.singleton().started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                Mage.singleton.startServices(initial: true);
                
                var usersFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/users")
                ) { (request) -> HTTPStubsResponse in
                    usersFetchStubCalled = true;
                    let stubPath = OHPathForFile("users.json", MageTests.self);
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
                                
                expect(usersFetchStubCalled).toEventually(beTrue());
                expect(observationsFetchStubCalled).toEventually(beTrue());
                expect(locationsFetchStubCalled).toEventually(beTrue());
                expect(ObservationPushService.singleton.started).toEventually(beTrue());
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                expect(AttachmentPushService.singleton().started).toEventually(beTrue());
                expect(LocationService.singleton().started).to(beTrue());
                expect(LocationFetchService.singleton().started).to(beTrue());
            }
            
            it("should fetch events") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1

                var eventsFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events")
                ) { (request) -> HTTPStubsResponse in
                    eventsFetchStubCalled = true;
                    let stubPath = OHPathForFile("events.json", MageTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var usersFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/users/myself")
                ) { (request) -> HTTPStubsResponse in
                    usersFetchStubCalled = true;
                    let stubPath = OHPathForFile("myself.json", MageTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var iconsStubCalled = false;
                
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/form/icons.zip")
                ) { (request) -> HTTPStubsResponse in
                    iconsStubCalled = true;
                    let stubPath = OHPathForFile("plantsAnimalsBuildingsIcons.zip", MageTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/zip"]);
                }
                
                var userIconFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/users/userabc/icon")
                ) { (request) -> HTTPStubsResponse in
                    userIconFetchStubCalled = true;
                    let stubPath = OHPathForFile("test_marker.png", MageTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                var userAvatarFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/users/userabc/avatar")
                ) { (request) -> HTTPStubsResponse in
                    userAvatarFetchStubCalled = true;
                    let stubPath = OHPathForFile("test_marker.png", MageTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                var feedsFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/feeds")
                ) { (request) -> HTTPStubsResponse in
                    feedsFetchStubCalled = true;
                    return HTTPStubsResponse(jsonObject:[], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var featuresFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/layers/44/features")
                ) { (request) -> HTTPStubsResponse in
                    featuresFetchStubCalled = true;
                    return HTTPStubsResponse(jsonObject:[], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                var mageFormFetchedCalled = false;
                NotificationCenter.default.addObserver(forName: .MAGEFormFetched, object: nil, queue: nil) { notification in
                    mageFormFetchedCalled = true;
                }
                Mage.singleton.fetchEvents()
                
                expect(usersFetchStubCalled).toEventually(beTrue());
                expect(eventsFetchStubCalled).toEventually(beTrue());
                expect(iconsStubCalled).toEventually(beTrue());
                expect(userIconFetchStubCalled).toEventually(beTrue());
                expect(userAvatarFetchStubCalled).toEventually(beTrue());
                expect(feedsFetchStubCalled).toEventually(beTrue());
                expect(featuresFetchStubCalled).toEventually(beTrue());
                expect(mageFormFetchedCalled).toEventually(beTrue());
            }
            
            it("should start services and then stop") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                MageCoreDataFixtures.addEvent();
                expect(ObservationPushService.singleton.started).to(beFalse());
                expect(LocationService.singleton().started).to(beFalse());
                expect(LocationFetchService.singleton().started).to(beFalse());
                expect(ObservationFetchService.singleton.started).to(beFalse());
                expect(AttachmentPushService.singleton().started).to(beFalse());
                Mage.singleton.startServices(initial: false);
                
                var usersFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/users")
                ) { (request) -> HTTPStubsResponse in
                    usersFetchStubCalled = true;
                    let stubPath = OHPathForFile("users.json", MageTests.self);
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
                
                expect(usersFetchStubCalled).toEventually(beTrue());
                expect(observationsFetchStubCalled).toEventually(beTrue());
                expect(locationsFetchStubCalled).toEventually(beTrue());
                expect(ObservationPushService.singleton.started).toEventually(beTrue());
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                expect(AttachmentPushService.singleton().started).toEventually(beTrue());
                expect(LocationService.singleton().started).to(beTrue());
                expect(LocationFetchService.singleton().started).to(beTrue());
                
                Mage.singleton.stopServices();
                
                expect(ObservationPushService.singleton.started).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Observation Push Service still running")
                // Location Service does not stop when all services are stopped
                expect(LocationService.singleton().started).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Location Service still running")
                expect(LocationFetchService.singleton().started).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Location Fetch Service still running")
                expect(ObservationFetchService.singleton.started).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Observation Fetch Service still running")
                expect(AttachmentPushService.singleton().started).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(100), description: "Attachment Push Service still running")
            }
        }
    }
}
