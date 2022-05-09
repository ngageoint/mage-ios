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
    var eventChoosenCalled = false
    var eventChoosenEvent: Event?
    func eventChoosen(_ event: Event!) {
        eventChoosenCalled = true
        eventChoosenEvent = event
    }
}

class EventChooserCoordinatorTests : KIFSpec {
    override func spec() {
        
        describe("EventChooserCoordinatorTests") {
            
            var window: UIWindow?
            var coordinator: EventChooserCoordinator?
            var navigationController: UINavigationController?
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                navigationController = UINavigationController()
                UserDefaults.standard.baseServerUrl = "https://magetest"
                window = TestHelpers.getKeyWindowVisible()
                window!.rootViewController = navigationController
            }
            
            afterEach {
                navigationController?.viewControllers = []
                window?.rootViewController?.dismiss(animated: false, completion: nil)
                window?.rootViewController = nil
                navigationController = nil
                coordinator = nil
                TestHelpers.clearAndSetUpStack()
            }
            
            it("Should load the event chooser with no events") {
                
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
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                tester().waitForView(withAccessibilityLabel: "RETURN TO LOGIN")
                TestHelpers.printAllAccessibilityLabelsInWindows()
                tester().tapView(withAccessibilityLabel: "RETURN TO LOGIN")
            }
            
            it("Should load the event chooser with no events and then get them from the server") {
                
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
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                tester().waitForView(withAccessibilityLabel: "MY RECENT EVENTS (1)")
                tester().waitForView(withAccessibilityLabel: "OTHER EVENTS (2)")
            }
            
            it("Should load the event chooser with no events and then get one from the server and auto select") {
                
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
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                expect(delegate.eventChoosenCalled).toEventually(beTrue())
                expect(delegate.eventChoosenEvent?.remoteId).to(equal(1))
            }
            
            it("Should load the current event") {
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [2])
                UserDefaults.standard.currentUserId = "userabc"
                Server.setCurrentEventId(2)
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event 2", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                
                let delegate = MockEventChooserDelegate()
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                
                expect(delegate.eventChoosenCalled).toEventually(beTrue())
                expect(delegate.eventChoosenEvent?.remoteId).to(equal(2))
            }
            
            it("Should show the event picker if the current event is no longer around") {
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                UserDefaults.standard.currentUserId = "userabc"
                Server.setCurrentEventId(1)
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event 2", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                MageCoreDataFixtures.addEvent(remoteId: 3, name: "Event 3", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUserToEvent(eventId: 3, userId: "userabc")
                
                let delegate = MockEventChooserDelegate()
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                
                expect(delegate.eventChoosenCalled).to(beFalse())
                tester().waitForView(withAccessibilityLabel: "Event 3")
                expect(Server.currentEventId).to(beNil())
            }
            
            it("Should load the event chooser with no events and then get a not recent one from the server and auto select") {
                
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
                
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [2])
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventChooserDelegate()
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                expect(delegate.eventChoosenCalled).toEventually(beTrue())
                expect(delegate.eventChoosenEvent?.remoteId).to(equal(1))
            }

            it("Should load the event chooser with no events and then get one not recent from the server") {
                
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
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                expect(delegate.eventChoosenCalled).toEventually(beTrue())
                expect(delegate.eventChoosenEvent?.remoteId).to(equal(1))
            }
            
            it("Should load the event chooser with events then get new ones") {
                
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
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                
                // first the coordinator will go load 2 events and be fine
                // then it should load the three different events and present a refresh button which will update the event list
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                tester().waitForView(withAccessibilityLabel: "OTHER EVENTS (2)")
                tester().waitForView(withAccessibilityLabel: "Event 2")
                
                tester().waitForView(withAccessibilityLabel: "Refresh Events")
                tester().wait(forTimeInterval: 5)
                tester().waitForCell(at: IndexPath(row: 1, section: 2), inTableViewWithAccessibilityIdentifier: "Event Table")
                tester().tapView(withAccessibilityLabel: "Refresh Events")
                tester().waitForCell(at: IndexPath(row: 2, section: 2), inTableViewWithAccessibilityIdentifier: "Event Table")
                tester().waitForView(withAccessibilityLabel: "OTHER EVENTS (3)")
                tester().waitForView(withAccessibilityLabel: "Animal")
            }
            
            it("should load the event chooser with one event not recent but not pick it because showEventChooserOnce was set") {
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
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                tester().waitForView(withAccessibilityLabel: "Other Events (1)")
                expect(delegate.eventChoosenCalled).to(beFalse())
                expect(UserDefaults.standard.showEventChooserOnce).to(beFalse())
            }
            
            it("should load the event chooser with one event recent but not pick it because showEventChooserOnce was set") {
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
                coordinator = EventChooserCoordinator(viewController: navigationController, andDelegate: delegate, andScheme: MAGEScheme.scheme())
                
                coordinator?.start()
                
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                tester().waitForView(withAccessibilityLabel: "My Recent Events (1)")
                expect(delegate.eventChoosenCalled).to(beFalse())
                expect(UserDefaults.standard.showEventChooserOnce).to(beFalse())
            }
            
        }
    }
}
