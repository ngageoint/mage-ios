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

class ObservationFetchServiceTests: MageInjectionTestCase {
    
    override func setUp() {
        super.setUp()
        ObservationFetchService.singleton.stop();
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.serverMajorVersion = 6;
        UserDefaults.standard.serverMinorVersion = 0;
        
        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "attachmentFormPlusOne")
        MageCoreDataFixtures.addUser(userId: "userabc")
        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
        Server.setCurrentEventId(1);
        UserDefaults.standard.currentUserId = "userabc";
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
        ]
        UserUtility.singleton.resetExpiration()
    }
    
    override func tearDown() {
        super.tearDown()
        ObservationFetchService.singleton.stop();
    }
    
    func testShouldStartTheObservationFetchsService() {
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
    
    func testShouldEnsureTheTimerFires() {
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
        expect(observationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called once");
        tester().wait(forTimeInterval: 1.1)
        expect(observationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called twice");
    }
    
    func testShouldEnsureTheTimerFiresAfterAFailureToPullInitial() {
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
        expect(observationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called once");
        tester().wait(forTimeInterval: 1.1)
        expect(observationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called twice");
    }
    
    func testShouldEnsureTheTimerFiresAfterAFailureToPull() {
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
        expect(observationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called once");
        tester().wait(forTimeInterval: 1.1)
        expect(observationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called twice");
    }
    
    func testShouldEnsureTheTimerFiresAsAWayToCheckIfWeShouldFetch() {
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
        expect(observationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called once");
    }
    
    func testShouldEnsureTheTimerFiresAsAWayToCheckIfWeShouldFetchOnInitialPull() {
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
        expect(observationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called once");
    }
    
    func testShouldStartTheTimerIfStopIsCalledImmediatelyBeforeStart() {
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
        expect(observationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called once");
        ObservationFetchService.singleton.stop()
        ObservationFetchService.singleton.start(initial: false)
        expect(observationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called twice");
    }
    
    func testShouldKickTheTimerIfThePreferenceChanges() {
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
        expect(observationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called once");
        tester().wait(forTimeInterval: 1.1)
        expect(observationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called twice");
        UserDefaults.standard.observationFetchFrequency = 2
        tester().wait(forTimeInterval: 0.5)
        expect(observationsFetchStubCalled).toEventually(equal(3), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called three times");
    }
    
    func testShouldChangeTheTimeAndNotResultInTwoTimers() {
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
        expect(observationsFetchStubCalled).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called once");
        tester().wait(forTimeInterval: 0.1)
        UserDefaults.standard.observationFetchFrequency = 1
        expect(observationsFetchStubCalled).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called twice");
        tester().wait(forTimeInterval: 1.1)
        expect(observationsFetchStubCalled).toEventually(equal(3), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations stub not called three times");
        tester().wait(forTimeInterval: 1.1)
        expect(observationsFetchStubCalled).to(equal(4));
    }
}
