//
//  LocationFetchServiceTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs

@testable import MAGE

class LocationFetchServiceTests: KIFSpec {
    
    override func spec() {
        describe("LocationFetchService Tests") {
            
            beforeEach {
                LocationFetchService.singleton.stop();

                var cleared = false;
                while (!cleared) {
                    let clearMap = TestHelpers.clearAndSetUpStack()
                    cleared = (clearMap[String(describing: Location.self)] ?? false) && (clearMap[String(describing: User.self)] ?? false)
                    
                    if (!cleared) {
                        cleared = Location.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0 && User.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0
                    }
                    
                    if (!cleared) {
                        Thread.sleep(forTimeInterval: 0.5);
                    }
                    
                }
                
                expect(Location.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations still exist in default");
                
                expect(Location.mr_findAll(in: NSManagedObjectContext.mr_rootSaving())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations still exist in root");
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.serverMajorVersion = 6;
                UserDefaults.standard.serverMinorVersion = 0;
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "attachmentFormPlusOne")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                Server.setCurrentEventId(1);
                UserDefaults.standard.currentUserId = "userabc";
                NSManagedObject.mr_setDefaultBatchSize(0);
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
                ]
                UserUtility.singleton.resetExpiration()
            }
            
            afterEach {
                LocationFetchService.singleton.stop();
                expect(LocationFetchService.singleton.started).toEventually(beFalse());
                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("should start the location fetch service") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                expect(LocationFetchService.singleton.started).to(beFalse());
                                
                var locationsFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/locations/users")
                ) { (request) -> HTTPStubsResponse in
                    locationsFetchStubCalled = true;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                LocationFetchService.singleton.start()
                expect(LocationFetchService.singleton.started).toEventually(beTrue());
                expect(locationsFetchStubCalled).toEventually(beTrue());
                LocationFetchService.singleton.stop();
                expect(LocationFetchService.singleton.started).toEventually(beFalse());
            }
            
            it("should ensure the timer fires") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.userFetchFrequency = 1
                expect(LocationFetchService.singleton.started).to(beFalse());
                
                var locationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/locations/users")
                ) { (request) -> HTTPStubsResponse in
                    locationsFetchStubCalled = locationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                LocationFetchService.singleton.start()
                expect(LocationFetchService.singleton.started).toEventually(beTrue());
                expect(locationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called once");
                tester().wait(forTimeInterval: 1.1)
                expect(locationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called twice");
            }
            
            it("should ensure the timer fires after a failure to pull") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.userFetchFrequency = 1
                MageCoreDataFixtures.addEvent();
                expect(LocationFetchService.singleton.started).to(beFalse());

                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var locationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/locations/users")
                ) { (request) -> HTTPStubsResponse in
                    locationsFetchStubCalled = locationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 404, headers: ["Content-Type": "application/json"]);
                }
                
                LocationFetchService.singleton.start()
                expect(LocationFetchService.singleton.started).toEventually(beTrue());
                expect(locationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called once");
                tester().wait(forTimeInterval: 1.1)
                expect(locationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called twice");
            }
            
            it("should ensure the timer fires as a way to check if we should fetch") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.userFetchFrequency = 1
                // 2 is none
                UserDefaults.standard.set(2, forKey: "locationFetchNetworkOption")
                MageCoreDataFixtures.addEvent();
                expect(LocationFetchService.singleton.started).to(beFalse());

                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var locationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/locations/users")
                ) { (request) -> HTTPStubsResponse in
                    locationsFetchStubCalled = locationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 404, headers: ["Content-Type": "application/json"]);
                }
                
                LocationFetchService.singleton.start()
                expect(LocationFetchService.singleton.started).toEventually(beTrue());
                tester().wait(forTimeInterval: 1.5)
                // 0 is all
                UserDefaults.standard.set(0, forKey: "locationFetchNetworkOption")
                expect(locationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called once");
            }
            
            it("should start the timer if stop is called immediately before start") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.userFetchFrequency = 1
                MageCoreDataFixtures.addEvent();
                expect(LocationFetchService.singleton.started).to(beFalse());

                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var locationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/locations/users")
                ) { (request) -> HTTPStubsResponse in
                    locationsFetchStubCalled = locationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                LocationFetchService.singleton.start()
                expect(LocationFetchService.singleton.started).toEventually(beTrue());
                expect(locationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called once");
                LocationFetchService.singleton.stop()
                LocationFetchService.singleton.start()
                expect(locationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called twice");
            }
            
            it("should kick the timer if the preference changes") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.userFetchFrequency = 1
                MageCoreDataFixtures.addEvent();
                expect(LocationFetchService.singleton.started).to(beFalse());

                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var locationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/locations/users")
                ) { (request) -> HTTPStubsResponse in
                    locationsFetchStubCalled = locationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                LocationFetchService.singleton.start()
                expect(LocationFetchService.singleton.started).toEventually(beTrue());
                expect(locationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called once");
                tester().wait(forTimeInterval: 1.5)
                expect(locationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called twice");
                UserDefaults.standard.userFetchFrequency = 2
                tester().wait(forTimeInterval: 0.5)
                expect(locationsFetchStubCalled).toEventually(equal(3), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called three times");
            }
            
            it("should change the time and not result in two timers") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.userFetchFrequency = 2
                MageCoreDataFixtures.addEvent();
                expect(LocationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var locationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/locations/users")
                ) { (request) -> HTTPStubsResponse in
                    locationsFetchStubCalled = locationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                LocationFetchService.singleton.start()
                expect(LocationFetchService.singleton.started).toEventually(beTrue());
                expect(locationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called once");
                tester().wait(forTimeInterval: 0.1)
                UserDefaults.standard.userFetchFrequency = 1
                expect(locationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called twice");
                tester().wait(forTimeInterval: 1.5)
                expect(locationsFetchStubCalled).toEventually(equal(3), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called three times");
                tester().wait(forTimeInterval: 1.1)
                expect(locationsFetchStubCalled).toEventually(equal(4), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Locations stub not called four times");
            }
        }
    }
}
