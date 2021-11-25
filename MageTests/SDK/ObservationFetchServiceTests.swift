//
//  ObservationFetchServiceTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/23/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs

@testable import MAGE

class ObservationFetchServiceTests: KIFSpec {
    
    override func spec() {
        describe("ObservationFetchService Tests") {
            
            beforeEach {
                var cleared = false;
                while (!cleared) {
                    let clearMap = TestHelpers.clearAndSetUpStack()
                    cleared = (clearMap[String(describing: Observation.self)] ?? false) && (clearMap[String(describing: ObservationImportant.self)] ?? false) && (clearMap[String(describing: User.self)] ?? false)
                    
                    if (!cleared) {
                        cleared = Observation.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0 && ObservationImportant.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0 && User.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0
                    }
                    
                    if (!cleared) {
                        Thread.sleep(forTimeInterval: 0.5);
                    }
                    
                }
                
                expect(Observation.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations still exist in default");
                
                expect(Observation.mr_findAll(in: NSManagedObjectContext.mr_rootSaving())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations still exist in root");
                
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
            }
            
            afterEach {
                ObservationFetchService.singleton.stop();
                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("should start the observation fetch service") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                MageCoreDataFixtures.addEvent();
                expect(ObservationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var observationsFetchStubCalled = false;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations")
                ) { (request) -> HTTPStubsResponse in
                    observationsFetchStubCalled = true;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                ObservationFetchService.singleton.start(initial: true)
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                expect(observationsFetchStubCalled).toEventually(beTrue());

            }
            
            it("should ensure the timer fires") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.observationFetchFrequency = 1
                MageCoreDataFixtures.addEvent();
                expect(ObservationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var observationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations")
                ) { (request) -> HTTPStubsResponse in
                    observationsFetchStubCalled = observationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                ObservationFetchService.singleton.start(initial: true)
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                expect(observationsFetchStubCalled).toEventually(equal(1));
                tester().wait(forTimeInterval: 1.1)
                expect(observationsFetchStubCalled).toEventually(equal(2));
            }
            
            it("should ensure the timer fires after a failure to pull initial") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.observationFetchFrequency = 1
                MageCoreDataFixtures.addEvent();
                expect(ObservationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var observationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations")
                ) { (request) -> HTTPStubsResponse in
                    observationsFetchStubCalled = observationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 404, headers: ["Content-Type": "application/json"]);
                }
                
                ObservationFetchService.singleton.start(initial: true)
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                expect(observationsFetchStubCalled).toEventually(equal(1));
                tester().wait(forTimeInterval: 1.1)
                expect(observationsFetchStubCalled).toEventually(equal(2));
            }
            
            it("should ensure the timer fires after a failure to pull") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.observationFetchFrequency = 1
                MageCoreDataFixtures.addEvent();
                expect(ObservationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var observationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations")
                ) { (request) -> HTTPStubsResponse in
                    observationsFetchStubCalled = observationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 404, headers: ["Content-Type": "application/json"]);
                }
                
                ObservationFetchService.singleton.start(initial: false)
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                expect(observationsFetchStubCalled).toEventually(equal(1));
                tester().wait(forTimeInterval: 1.1)
                expect(observationsFetchStubCalled).toEventually(equal(2));
            }
            
            it("should ensure the timer fires as a way to check if we should fetch") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.observationFetchFrequency = 1
                // 2 is none
                UserDefaults.standard.set(2, forKey: "observationFetchNetworkOption")
                MageCoreDataFixtures.addEvent();
                expect(ObservationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var observationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations")
                ) { (request) -> HTTPStubsResponse in
                    observationsFetchStubCalled = observationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 404, headers: ["Content-Type": "application/json"]);
                }
                
                ObservationFetchService.singleton.start(initial: false)
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                tester().wait(forTimeInterval: 1.5)
                // 0 is all
                UserDefaults.standard.set(0, forKey: "observationFetchNetworkOption")
                expect(observationsFetchStubCalled).toEventually(equal(1));
            }
            
            it("should ensure the timer fires as a way to check if we should fetch on initial pull") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.observationFetchFrequency = 1
                // 2 is none
                UserDefaults.standard.set(2, forKey: "observationFetchNetworkOption")
                MageCoreDataFixtures.addEvent();
                expect(ObservationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var observationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations")
                ) { (request) -> HTTPStubsResponse in
                    observationsFetchStubCalled = observationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 404, headers: ["Content-Type": "application/json"]);
                }
                
                ObservationFetchService.singleton.start(initial: true)
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                tester().wait(forTimeInterval: 1.8)
                // 0 is all
                UserDefaults.standard.set(0, forKey: "observationFetchNetworkOption")
                expect(observationsFetchStubCalled).toEventually(equal(1));
            }
            
            it("should start the timer if stop is called immediately before start") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.observationFetchFrequency = 1
                MageCoreDataFixtures.addEvent();
                expect(ObservationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var observationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations")
                ) { (request) -> HTTPStubsResponse in
                    observationsFetchStubCalled = observationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                ObservationFetchService.singleton.start(initial: true)
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                expect(observationsFetchStubCalled).toEventually(equal(1));
                ObservationFetchService.singleton.stop()
                ObservationFetchService.singleton.start(initial: false)
                expect(observationsFetchStubCalled).toEventually(equal(2));
            }
            
            it("should kick the timer if the preference changes") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.observationFetchFrequency = 1
                MageCoreDataFixtures.addEvent();
                expect(ObservationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var observationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations")
                ) { (request) -> HTTPStubsResponse in
                    observationsFetchStubCalled = observationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                ObservationFetchService.singleton.start(initial: true)
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                expect(observationsFetchStubCalled).toEventually(equal(1));
                tester().wait(forTimeInterval: 1.1)
                expect(observationsFetchStubCalled).toEventually(equal(2));
                UserDefaults.standard.observationFetchFrequency = 2
                tester().wait(forTimeInterval: 0.5)
                expect(observationsFetchStubCalled).toEventually(equal(3));
            }
            
            it("should change the time and not result in two timers") {
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.currentEventId = 1
                UserDefaults.standard.observationFetchFrequency = 2
                MageCoreDataFixtures.addEvent();
                expect(ObservationFetchService.singleton.started).to(beFalse());
                
                UNUserNotificationCenter.current().removeAllDeliveredNotifications();
                
                var observationsFetchStubCalled = 0;
                stub(condition: isMethodGET() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations")
                ) { (request) -> HTTPStubsResponse in
                    observationsFetchStubCalled = observationsFetchStubCalled + 1;
                    return HTTPStubsResponse(jsonObject: [], statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                ObservationFetchService.singleton.start(initial: true)
                expect(ObservationFetchService.singleton.started).toEventually(beTrue());
                expect(observationsFetchStubCalled).toEventually(equal(1));
                tester().wait(forTimeInterval: 0.1)
                UserDefaults.standard.observationFetchFrequency = 1
                expect(observationsFetchStubCalled).toEventually(equal(2));
                tester().wait(forTimeInterval: 1.1)
                expect(observationsFetchStubCalled).toEventually(equal(3));
                tester().wait(forTimeInterval: 1.1)
                expect(observationsFetchStubCalled).to(equal(4));
            }
        }
    }
}
