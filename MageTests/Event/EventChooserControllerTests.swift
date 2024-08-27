//
//  EventChooserControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 4/13/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import MAGE

class MockEventSelectionDelegate: NSObject, EventSelectionDelegate {
    var didSelectCalled = false
    var eventSelected: Event?
    var actionButtonTappedCalled = false
    func didSelectEvent(event: Event) {
        didSelectCalled = true
        eventSelected = event
    }
    
    func actionButtonTapped() {
        actionButtonTappedCalled = true
    }
}

class EventChooserControllerTests : KIFSpec {
    override func spec() {
        
        xdescribe("EventChooserControllerTests") {
            
            var window: UIWindow?;
            var view: EventChooserController?;
            var navigationController: UINavigationController?;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                navigationController = UINavigationController();
                
                window = TestHelpers.getKeyWindowVisible();
                window!.rootViewController = navigationController;
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                navigationController = nil;
                view = nil;
                TestHelpers.clearAndSetUpStack();
            }
            
            it("Should load the event chooser with no events") {
                MageCoreDataFixtures.addUser(userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                tester().waitForView(withAccessibilityLabel: "RETURN TO LOGIN")
                tester().tapView(withAccessibilityLabel: "RETURN TO LOGIN")
                expect(delegate.actionButtonTappedCalled).to(beTrue())
            }
            
            it("Should load the event chooser with no events and then get them from the server") {
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event2", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addEvent(remoteId: 3, name: "Nope", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 3, userId: "userabc")
                
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                expect(delegate.actionButtonTappedCalled).to(beFalse())
            }
            
            it("Should load the event chooser with no events and then get one from the server and auto select") {
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                expect(delegate.didSelectCalled).toEventually(beTrue())
                expect(delegate.eventSelected?.remoteId).to(equal(1))
            }
            
            it("Should load the event chooser with no events and then get one not recent from the server") {
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [])
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Loading Events")
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Loading Events")
                expect(delegate.didSelectCalled).toEventually(beTrue())
                expect(delegate.eventSelected?.remoteId).to(equal(1))
            }
            
            it("Should load the event chooser with events then get an extra one") {
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [])
                UserDefaults.standard.currentUserId = "userabc"
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                
                MageCoreDataFixtures.addEvent(remoteId: 3, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUserToEvent(eventId: 3, userId: "userabc")
                
                view?.eventsFetchedFromServer()
                tester().waitForView(withAccessibilityLabel: "Refresh Events")
                tester().waitForCell(at: IndexPath(row: 1, section: 2), inCollectionViewWithAccessibilityIdentifier: "Event Table")
                tester().tapView(withAccessibilityLabel: "Refresh Events")
                tester().waitForCell(at: IndexPath(row: 2, section: 2), inCollectionViewWithAccessibilityIdentifier: "Event Table")
            }
            
            it("should load the event chooser with one event not recent") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [])
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                tester().waitForView(withAccessibilityLabel: "Other Events (1)")
                // when there is one event it will be automatically selected
                expect(delegate.didSelectCalled).toEventually(beTrue())
                expect(delegate.eventSelected?.remoteId).to(equal(1))
            }
            
            it("should load the event chooser with one event recent") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                tester().waitForView(withAccessibilityLabel: "My Recent Events (1)")
                // when there is one event it will be automatically selected
                expect(delegate.didSelectCalled).toEventually(beTrue())
                expect(delegate.eventSelected?.remoteId).to(equal(1))
            }
            
            it("should load the event chooser with one event not recent but not pick it because showEventChooserOnce was set") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [])
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"
                UserDefaults.standard.showEventChooserOnce = true
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                tester().waitForView(withAccessibilityLabel: "Other Events (1)")
                expect(delegate.didSelectCalled).to(beFalse())
                expect(UserDefaults.standard.showEventChooserOnce).to(beFalse())
            }
            
            it("should load the event chooser with one event recent but not pick it because showEventChooserOnce was set") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"
                UserDefaults.standard.showEventChooserOnce = true
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())

                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                tester().waitForView(withAccessibilityLabel: "My Recent Events (1)")
                expect(delegate.didSelectCalled).to(beFalse())
                expect(UserDefaults.standard.showEventChooserOnce).to(beFalse())
                tester().waitForView(withAccessibilityLabel: "You are a part of one event.  The observations you create and your reported location will be part of this event.")
            }
            
            it("should load the event chooser with one recent and one other event") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event2", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"

                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                // wait for fade out
                tester().wait(forTimeInterval: 0.8)
                tester().waitForView(withAccessibilityLabel: "My Recent Events (1)")

                tester().tapItem(at: IndexPath(row: 0, section: 1), inCollectionViewWithAccessibilityIdentifier: "Event Table")
                expect(delegate.didSelectCalled).toEventually(beTrue())
                expect(delegate.eventSelected?.remoteId).to(equal(1))
            }
            
            it("should load the event chooser with one recent and one other event refreshing taking too long") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event2", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")

                // wait for time out
                tester().wait(forTimeInterval: 12)
                
                tester().waitForView(withAccessibilityLabel: "Refreshing events seems to be taking a while...")
                
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing events seems to be taking a while...")
                
                tester().waitForView(withAccessibilityLabel: "My Recent Events (1)")
                
                tester().tapItem(at: IndexPath(row: 0, section: 1), inCollectionViewWithAccessibilityIdentifier: "Event Table")
                expect(delegate.didSelectCalled).toEventually(beTrue())
                expect(delegate.eventSelected?.remoteId).to(equal(1))
            }
            
            it("should load the event chooser with one recent and one other event") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", description: "Lorem ipsum dolor sit amet, no eos nonumes temporibus vituperatoribus, usu oporteat inimicus ex. Sint inimicus cum eu, libris melius oblique ad mel, et libris accusamus vix. Vel ut dolor aperiam debitis. Ius at diam ferri option, eum solet blandit deseruisse ea, eu ridens periculis sed. Nonumy utamur mel ut, eos eu nulla populo, sea habeo veniam tempor in. Ius et eius ancillae assueverit, sed cu probo putent labores, no atqui tacimates invenire duo. No usu probo repudiandae, quando cetero nominati quo et.", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event2", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"
                Server.setCurrentEventId(1);
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["id"] = "observationdef"
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                MageCoreDataFixtures.addObservationToEvent(eventId: 2)
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(2));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                observation.error = [
                    ObservationPushService.ObservationErrorStatusCode: 503,
                    ObservationPushService.ObservationErrorMessage: "Something Bad"
                ]
                let observation2: Observation = observations![1] as! Observation;
                observation2.dirty = true;
                observation2.error = [
                    ObservationPushService.ObservationErrorStatusCode: 503,
                    ObservationPushService.ObservationErrorMessage: "Something Really Bad"
                ]
                
                @Injected(\.nsManagedObjectContext)
                var context: NSManagedObjectContext?
                
                guard let context = context else { return }
                context.mr_saveToPersistentStoreAndWait();
                
                expect(Observation.mr_findAll()?.count).toEventually(equal(2))
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                // wait for fade out
                tester().wait(forTimeInterval: 0.8)
                tester().waitForView(withAccessibilityLabel: "My Recent Events (1)")
                tester().waitForView(withAccessibilityLabel: "Badge 1")
                tester().tapItem(at: IndexPath(row: 0, section: 2), inCollectionViewWithAccessibilityIdentifier: "Event Table")
                expect(delegate.didSelectCalled).toEventually(beTrue())
                expect(delegate.eventSelected?.remoteId).to(equal(2))
            }
            
            it("should not allow tapping an event the user is not in because it was removed after the view loaded") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event2", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addEvent(remoteId: 3, name: "Nope", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 3, userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                // wait for fade out
                tester().wait(forTimeInterval: 0.8)
                tester().waitForView(withAccessibilityLabel: "Other Events (2)")
                
                Event.mr_deleteAll(matching: NSPredicate(format: "remoteId = %d", 2), in: NSManagedObjectContext.mr_default())
                
                tester().tapItem(at: IndexPath(row: 0, section: 2), inCollectionViewWithAccessibilityIdentifier: "Event Table")
                tester().waitForView(withAccessibilityLabel: "Unauthorized")
                tester().tapView(withAccessibilityLabel: "Refresh Events")
                tester().waitForView(withAccessibilityLabel: "Other Events (1)")
            }
            
            it("should display all events the user is in and allow searching") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event2", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addEvent(remoteId: 3, name: "Nope", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc", recentEventIds: [1])
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 3, userId: "userabc")
                UserDefaults.standard.currentUserId = "userabc"
                
                let delegate = MockEventSelectionDelegate()
                view = EventChooserController(delegate: delegate, scheme: MAGEScheme.scheme())
                navigationController?.pushViewController(view!, animated: false)
                tester().waitForView(withAccessibilityLabel: "Refreshing Events")
                view?.eventsFetchedFromServer()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Refreshing Events")
                // wait for fade out
                tester().wait(forTimeInterval: 0.8)
                tester().waitForView(withAccessibilityLabel: "Other Events (2)")
                
                tester().waitForView(withAccessibilityLabel: "Please choose an event.  The observations you create and your reported location will be part of the selected event.")
                TestHelpers.printAllAccessibilityLabelsInWindows()
                tester().enterText("Even", intoViewWithAccessibilityLabel: "Search")
                tester().waitForView(withAccessibilityLabel: "Filtered (2)")
                tester().tapItem(at: IndexPath(row: 0, section: 0), inCollectionViewWithAccessibilityIdentifier: "Event Table")
                expect(delegate.didSelectCalled).toEventually(beTrue())
                expect(delegate.eventSelected?.remoteId).to(equal(1))
            }
        }
    }
}
