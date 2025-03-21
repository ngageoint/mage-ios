//
//  EventChooserCoordinatorTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/3/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs

@testable import MAGE

class MockEventChooserDelegate: NSObject, EventChooserDelegate {
    var eventChosenCalled = false
    var eventChosenEvent: Event?
    func eventChosen(event: Event) {
        eventChosenCalled = true
        eventChosenEvent = event
    }
}

// TODO: FLAKY TESTS
// BRENT: These tests sometimes CRASH.
class EventChooserCoordinatorTests : AsyncMageCoreDataTestCase {
    override open func setUp() async throws {
        print("XXX set up")
        try await super.setUp()
        await setUpViews()
        UserDefaults.standard.baseServerUrl = "https://magetest"
        TestHelpers.setupValidToken()
    }
    
    override open func tearDown() async throws {
        print("XXX tear down")
        try await super.tearDown()
        await tearDownViews()
    }
    
    @MainActor
    func setUpViews() {
        navigationController = UINavigationController()
        window = TestHelpers.getKeyWindowVisible()
        window!.rootViewController = navigationController
    }
    
    @MainActor
    func tearDownViews() {
        navigationController?.viewControllers = []
        window?.rootViewController?.dismiss(animated: false, completion: nil)
        window?.rootViewController = nil
        navigationController = nil
        coordinator = nil
    }
    
    var window: UIWindow?
    var coordinator: EventChooserCoordinator?
    var navigationController: UINavigationController?
    
    func testShouldLoadTheEventChooserWithNoEvents() {
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/myself")
        ) { (request) -> HTTPStubsResponse in
            let stubPath = OHPathForFile("myself.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        MageCoreDataFixtures.addUser(userId: "userabc")
        UserDefaults.standard.currentUserId = "userabc"
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        tester().waitForView(withAccessibilityLabel: "Loading Events")
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
        tester().waitForView(withAccessibilityLabel: "RETURN TO LOGIN")
        TestHelpers.printAllAccessibilityLabelsInWindows()
        tester().tapView(withAccessibilityLabel: "RETURN TO LOGIN")
    }
    
    func testShouldLoadTheEventChooserWithNoEventsAndThenGetThemFromTheServer() {
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
        
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
        UserDefaults.standard.currentUserId = "userabc"
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        tester().waitForView(withAccessibilityLabel: "Loading Events")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
        tester().waitForView(withAccessibilityLabel: "MY RECENT EVENTS (1)")
        tester().waitForView(withAccessibilityLabel: "OTHER EVENTS (2)")
    }
    
    @MainActor
    func testShouldLoadTheEventChooserWithNoEventsAndThenGetOneFromTheServerAndAutoSelect() async {
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
            let stubPath = OHPathForFile("events.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
        UserDefaults.standard.currentUserId = "userabc"
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        tester().waitForView(withAccessibilityLabel: "Loading Events")
        
        let predicate = NSPredicate { _, _ in
            return delegate.eventChosenCalled == true && delegate.eventChosenEvent?.remoteId == 1
        }
        let delegateExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [delegateExpectation], timeout: 2)
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
    }
    
    func testShouldLoadTheCurrentEvent() {
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [2])
        UserDefaults.standard.currentUserId = "userabc"
        Server.setCurrentEventId(2)
        
        MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event 2", formsJsonFile: "oneForm")
        MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        expect(delegate.eventChosenCalled).toEventually(beTrue())
        expect(delegate.eventChosenEvent?.remoteId).to(equal(2))
    }
    
    func testShouldShowTheEventPickerIfTheCurrentEventIsNoLongerAround() {
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
        UserDefaults.standard.currentUserId = "userabc"
        Server.setCurrentEventId(1)
        
        MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event 2", formsJsonFile: "oneForm")
        MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
        MageCoreDataFixtures.addEvent(remoteId: 3, name: "Event 3", formsJsonFile: "oneForm")
        MageCoreDataFixtures.addUserToEvent(eventId: 3, userId: "userabc")
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        expect(delegate.eventChosenCalled).to(beFalse())
        tester().waitForView(withAccessibilityLabel: "Event 3")
        expect(Server.currentEventId).to(beNil())
    }
    
    @MainActor
    func testShouldLoadTheEventChooserWithNoEventsAndThenGetANonRecentOneFromTheServerAndAutoSelect() async {
        let myselfExpectation = XCTestExpectation(description: "Myself Stub Called")
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/myself")
        ) { (request) -> HTTPStubsResponse in
            myselfExpectation.fulfill()
            let stubPath = OHPathForFile("myself.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        let eventsExpectation = XCTestExpectation(description: "Events Stub Called")
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events")
        ) { (request) -> HTTPStubsResponse in
            eventsExpectation.fulfill()
            let stubPath = OHPathForFile("events.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/userabc/icon")
        ) { (request) -> HTTPStubsResponse in
            return HTTPStubsResponse(jsonObject: [], statusCode: 404, headers: ["Content-Type": "image/png"])
        }
        
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/userabc/avatar")
        ) { (request) -> HTTPStubsResponse in
            return HTTPStubsResponse(jsonObject: [], statusCode: 404, headers: ["Content-Type": "image/png"])
        }
        
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [2])
        UserDefaults.standard.currentUserId = "userabc"
        
        let importedNotification = XCTNSNotificationExpectation(name: .MAGEEventsFetched)
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        tester().waitForView(withAccessibilityLabel: "Loading Events")
        tester().waitForAnimationsToFinish()
        
        await fulfillment(of: [myselfExpectation, eventsExpectation], timeout: 2)
        
        await fulfillment(of: [importedNotification], timeout: 2)
                
        let predicate = NSPredicate { _, _ in
            return delegate.eventChosenCalled == true && delegate.eventChosenEvent?.remoteId == 1
        }
        let delegateExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [delegateExpectation], timeout: 2)
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
    }

    @MainActor
    func testShouldLoadTheEventChooserWithNoEventsAndThenGetOneNotRecentFromTheServer() async {
        
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
            let stubPath = OHPathForFile("events.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [])
        UserDefaults.standard.currentUserId = "userabc"
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        tester().waitForView(withAccessibilityLabel: "Loading Events")
        
        let predicate = NSPredicate { _, _ in
            return delegate.eventChosenCalled == true && delegate.eventChosenEvent?.remoteId == 1
        }
        let delegateExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [delegateExpectation], timeout: 2)
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
    }
    
    func testShouldLoadTheEventChooserWithEventsThenGetNewOnes() {
        
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
        
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [])
        UserDefaults.standard.currentUserId = "userabc"
        MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event 2", formsJsonFile: "oneForm")
        MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
        MageCoreDataFixtures.addEvent(remoteId: 3, name: "Event", formsJsonFile: "oneForm")
        MageCoreDataFixtures.addUserToEvent(eventId: 3, userId: "userabc")
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        // first the coordinator will go load 2 events and be fine
        // then it should load the three different events and present a refresh button which will update the event list
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
        tester().waitForView(withAccessibilityLabel: "OTHER EVENTS (2)")
        tester().waitForView(withAccessibilityLabel: "Event 2")
        
        tester().waitForView(withAccessibilityLabel: "Refresh Events")
        tester().wait(forTimeInterval: 5)
        tester().waitForCell(at: IndexPath(row: 1, section: 2), inCollectionViewWithAccessibilityIdentifier: "Event Table")
        tester().tapView(withAccessibilityLabel: "Refresh Events")
        tester().waitForCell(at: IndexPath(row: 2, section: 2), inCollectionViewWithAccessibilityIdentifier: "Event Table")
        tester().waitForView(withAccessibilityLabel: "OTHER EVENTS (3)")
        tester().waitForView(withAccessibilityLabel: "Animal")
    }
    
    func testShouldLoadTheEventChooserWithEventsThenGetOneNewAndNotAutoSelectIt() {
        
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
            let stubPath = OHPathForFile("events.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [])
        UserDefaults.standard.currentUserId = "userabc"
        MageCoreDataFixtures.addEvent( remoteId: 2, name: "Event 2", formsJsonFile: "oneForm")
        MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
        MageCoreDataFixtures.addEvent(remoteId: 3, name: "Event", formsJsonFile: "oneForm")
        MageCoreDataFixtures.addUserToEvent(eventId: 3, userId: "userabc")
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        // first the coordinator will go load 2 events and be fine
        // then it should load one event and present a refresh button which will update the event list
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
        tester().waitForView(withAccessibilityLabel: "OTHER EVENTS (2)")
        tester().waitForView(withAccessibilityLabel: "Event 2")
        
        tester().waitForView(withAccessibilityLabel: "Refresh Events")
        tester().wait(forTimeInterval: 5)
        tester().waitForCell(at: IndexPath(row: 1, section: 2), inCollectionViewWithAccessibilityIdentifier: "Event Table")
        tester().tapView(withAccessibilityLabel: "Refresh Events")
        tester().waitForCell(at: IndexPath(row: 0, section: 2), inCollectionViewWithAccessibilityIdentifier: "Event Table")
        tester().waitForView(withAccessibilityLabel: "OTHER EVENTS (1)")
        tester().waitForView(withAccessibilityLabel: "Animal")
        expect(delegate.eventChosenCalled).to(beFalse())
    }
    
    func testShouldLoadTheEventChooserWithOneEventNotRecentButNotPickItBecauseShowEventChooserOnceWasSet() {
        UserDefaults.standard.showEventChooserOnce = true
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
            let stubPath = OHPathForFile("events.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [])
        UserDefaults.standard.currentUserId = "userabc"
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        tester().waitForView(withAccessibilityLabel: "Loading Events")
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
        tester().waitForView(withAccessibilityLabel: "Other Events (1)")
        expect(delegate.eventChosenCalled).to(beFalse())
        expect(UserDefaults.standard.showEventChooserOnce).to(beFalse())
    }
    
    func testShouldLoadTheEventChooserWithOneEventRecentButNotPickItBecauseShowEventChooserOnceWasSet() {
        UserDefaults.standard.showEventChooserOnce = true
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
            let stubPath = OHPathForFile("events.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
        UserDefaults.standard.currentUserId = "userabc"
        
        let delegate = MockEventChooserDelegate()
        coordinator = EventChooserCoordinator(viewController: navigationController!, delegate: delegate, scheme: MAGEScheme.scheme())
        
        coordinator?.start()
        
        tester().waitForView(withAccessibilityLabel: "Loading Events")
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
        tester().waitForView(withAccessibilityLabel: "My Recent Events (1)")
        expect(delegate.eventChosenCalled).to(beFalse())
        expect(UserDefaults.standard.showEventChooserOnce).to(beFalse())
    }
    
}
