//
//  ObservationPropertiesEditCoordinator.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/30/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import sf_ios

import MagicalRecord

@testable import MAGE

class ObservationEditCoordinatorTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationEditCoordinator") {
            var controller: UIViewController!
            var window: UIWindow!
            var stackSetup = false;
            
            beforeEach {
                if (!stackSetup) {
                    TestHelpers.clearAndSetUpStack();
                    stackSetup = true;
                }
                MageCoreDataFixtures.clearAllData();
                window = TestHelpers.getKeyWindowVisible();
                controller = UIViewController();
                window.rootViewController = controller;
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                
                NSDate.setDisplayGMT(true);
            }
            
            afterEach {
                if let safePresented = controller.presentedViewController {
                    if safePresented is UINavigationController {
                        let nav: UINavigationController = safePresented as! UINavigationController;
                        nav.popToRootViewController(animated: false)
                    }
                    safePresented.dismiss(animated: false, completion: nil);
                }
                MageCoreDataFixtures.clearAllData();
            }
            
            it("initialize the coordinator with a geometry") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                
                expect(coordinator.observation?.managedObjectContext?.mr_workingName()).to(equal("Observation New Context"));
                expect(coordinator.observation?.managedObjectContext?.parent).to(equal(NSManagedObjectContext.mr_rootSaving()));
                expect(coordinator.newObservation).to(beTrue());
                
                expect(coordinator.rootViewController).to(equal(controller));
                expect(coordinator.delegate).toNot(beNil());
            }
            
            it("initialize the coordinator with an observation") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    let observation = ObservationBuilder.createPointObservation(context: localContext);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                })
                let observation: Observation! = Observation.mr_findFirst(in: .mr_default());
                let initialContext = observation.managedObjectContext;

                let delegate: ObservationEditDelegate = MockObservationEditDelegate();

                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, observation: observation);

                expect(coordinator.observation?.managedObjectContext).toNot(equal(initialContext));
                expect(coordinator.observation?.managedObjectContext?.mr_workingName()).to(equal("Observation Edit Context"));
                expect(coordinator.observation?.managedObjectContext?.parent).to(equal(NSManagedObjectContext.mr_rootSaving()));
                expect(coordinator.newObservation).to(beFalse());
                expect(coordinator.rootViewController).to(equal(controller));
                expect(coordinator.delegate).toNot(beNil());
            }
            
            it("should not allow a user not in the event to edit an observation") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    let observation = ObservationBuilder.createPointObservation(context: localContext);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                })
                let observation: Observation! = Observation.mr_findFirst(in: .mr_default());
                
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, observation: observation);
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                coordinator.start();
                                
                tester().waitForView(withAccessibilityLabel: "You are not part of this event");
                let alert: UIAlertController = (UIApplication.getTopViewController() as! UIAlertController);
                expect(alert.title).to(equal("You are not part of this event"));
                tester().tapView(withAccessibilityLabel: "OK");
            }
            
            it("should allow a user in the event to edit an observation") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    let observation = ObservationBuilder.createPointObservation(eventId: 1, context: localContext);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                })
                let observation: Observation! = Observation.mr_findFirst(in: .mr_default());
                
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, observation: observation);
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                tester().wait(forTimeInterval: 0.5);
                coordinator.start();
                tester().waitForView(withAccessibilityLabel: "timestamp");
                tester().expect(viewTester().usingLabel("timestamp").view, toContainText: "1970-04-26 17:46 GMT")
                
                tester().expect(viewTester().usingLabel("geometry").view, toContainText: "40.00850, -105.26780 ");
            }
            
            it("should show form chooser with new observation") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                tester().wait(forTimeInterval: 0.5);

                coordinator.start();

                tester().waitForView(withAccessibilityLabel: "Add A Form To Your Observation");
                tester().waitForView(withAccessibilityLabel: "Test");
                tester().tapView(withAccessibilityLabel: "Test");
            }
            
            it("should show form chooser with new observation and pick a form") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                tester().wait(forTimeInterval: 0.5);
                
                coordinator.start();
                TestHelpers.printAllAccessibilityLabelsInWindows();

                tester().waitForView(withAccessibilityLabel: "Test");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().tapView(withAccessibilityLabel: "Test");
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
            }
            
            xit("should show form chooser with new observation and pick a form and select a combo field") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: MockObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                coordinator.start();
                NSLog("started coordinator")
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "Test");
                NSLog("found view with label test")
                tester().tapView(withAccessibilityLabel: "Test");
                NSLog("Tapped view with test");
                tester().waitForAnimationsToFinish();
                NSLog("wait for field 1");
                tester().waitForView(withAccessibilityLabel: "field1");
                NSLog("found field 1");
                tester().tapView(withAccessibilityLabel: "field1");
                NSLog("Tapped view with field 1");
                
                tester().waitForAnimationsToFinish();
                NSLog("waiting for view with choices");
                tester().waitForView(withAccessibilityLabel: "choices");
                NSLog("found view with choices");
                tester().tapRow(at: IndexPath(row: 1, section: 0), inTableViewWithAccessibilityIdentifier: "choices")
                
                tester().expect(viewTester().usingLabel("field1")?.view, toContainText: "Low")
            }
            
            xit("should show form chooser with new observation and pick a form and select the observation geometry field") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "geometryField")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: MockObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                coordinator.start();
                                
                tester().waitForView(withAccessibilityLabel: "Test");
                tester().tapView(withAccessibilityLabel: "Test");
                
                
                tester().waitForTappableView(withAccessibilityLabel: "geometry");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().tapView(withAccessibilityLabel: "geometry");
                
                
                
                tester().waitForView(withAccessibilityLabel: "Latitude");
                tester().clearText(fromAndThenEnterText: "40.1", intoViewWithAccessibilityLabel: "Latitude Value");
                tester().clearText(fromAndThenEnterText: "-105.26", intoViewWithAccessibilityLabel: "Longitude Value");
                // need to wait so that the text field can change the geometry.
                // TODO: Fix that
                tester().wait(forTimeInterval: 1.0);
                
                tester().waitForTappableView(withAccessibilityLabel: "Done");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().tapView(withAccessibilityLabel: "Done");
                
                
                let obsPoint: SFPoint = coordinator.observation?.geometry as! SFPoint;
                expect(obsPoint.y).to(beCloseTo(40.1));
                expect(obsPoint.x).to(beCloseTo(-105.26));
                TestHelpers.printAllAccessibilityLabelsInWindows();
                
                expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "40.10000, -105.26000"
                expect((viewTester().usingLabel("location field1")!.view as! MDCButton).currentTitle) == "NO LOCATION SET"
            }
            
            xit("should show form chooser with new observation and pick a form and select a geometry field") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "geometryField")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: MockObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                coordinator.start();
                                
                tester().waitForView(withAccessibilityLabel: "Test");
                tester().tapView(withAccessibilityLabel: "Test");
                
                
                tester().waitForTappableView(withAccessibilityLabel: "field1");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().tapView(withAccessibilityLabel: "field1");
                
                
                
                tester().waitForView(withAccessibilityLabel: "Latitude");
                tester().clearText(fromAndThenEnterText: "40.0", intoViewWithAccessibilityLabel: "Latitude");
                tester().clearText(fromAndThenEnterText: "-105.26", intoViewWithAccessibilityLabel: "Longitude");
                // need to wait so that the text field can change the geometry.
                // TODO: Fix that
                tester().wait(forTimeInterval: 1.0);
                
                tester().waitForTappableView(withAccessibilityLabel: "Done");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().tapView(withAccessibilityLabel: "Done");
                
                
                let forms = (coordinator.observation?.properties!["forms"])! as! [[String: Any]];
                let fieldPoint: SFPoint = forms[0]["field1"] as! SFPoint;
                expect(fieldPoint.y).to(beCloseTo(40.0));
                expect(fieldPoint.x).to(beCloseTo(-105.26));
                
                expect((viewTester().usingLabel("location field1")!.view as! MDCButton).currentTitle) == "40.00000, -105.26000"
                expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "40.00850, -105.26780"
            }
            
            xit("should show form chooser with new observation and pick a form and set the observations date") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "geometryField")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                let formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mmZ";
                formatter.locale = Locale(identifier: "en_US_POSIX");
                                                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: MockObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                // set the time on the observation to something so the date picker functions correctly
                coordinator.observation?.properties?["timestamp"] = "2020-10-29T07:00:00.000Z"
                coordinator.observation?.timestamp = formatter.date(from: "2020-10-29T07:00:00.000Z");
                coordinator.start();
                
                tester().waitForView(withAccessibilityLabel: "Test");
                tester().tapView(withAccessibilityLabel: "Test");
                
                
                tester().waitForTappableView(withAccessibilityLabel: "timestamp");
                tester().tapView(withAccessibilityLabel: "timestamp");
                
                tester().waitForView(withAccessibilityLabel: "timestamp Date Picker");
                tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .forwardFromCurrentValue);
                tester().tapView(withAccessibilityLabel: "Done");
                
                let formatterWithSeconds = ISO8601DateFormatter()
                formatterWithSeconds.formatOptions =  [.withInternetDateTime, .withFractionalSeconds]
            
                let date = formatter.date(from: "2020-11-02T14:00Z")!;
                let timestampString: String? = coordinator.observation?.properties?["timestamp"] as? String;
                let observationDate: Date = formatterWithSeconds.date(from: timestampString!)!;
                
                expect(formatter.string(from: observationDate)) == formatter.string(from: date);
                expect(formatter.string(from: (coordinator.observation?.timestamp)!)) == formatter.string(from: date);
            }
            
            it("should show form chooser with new observation and cancel it") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                tester().wait(forTimeInterval: 0.5);

                coordinator.start();
                                
                tester().waitForView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
            }
            
            it("should cancel editing") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    let observation = ObservationBuilder.createPointObservation(eventId: 1, context: localContext);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                })
                let observation: Observation! = Observation.mr_findFirst(in: .mr_default());
                
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, observation: observation);
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                tester().wait(forTimeInterval: 0.5);

                coordinator.start();
                
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                                
                tester().waitForTappableView(withAccessibilityLabel: "Yes, Discard");
                tester().tapView(withAccessibilityLabel: "Yes, Discard");
            }
            
            it("should not add archived forms to the observation") {
                let formsJson: [[String: AnyHashable]] = [[
                    "name": "Suspect",
                    "description": "Information about a suspect",
                    "color": "#5278A2",
                    "id": 2,
                    "archived": true,
                    "min": 1,
                    "max": 1
                ], [
                    "name": "Vehicle",
                    "description": "Information about a vehicle",
                    "color": "#7852A2",
                    "id": 3,
                    "min": 1,
                    "max": 1
                ], [
                    "name": "Evidence",
                    "description": "Evidence form",
                    "color": "#52A278",
                    "id": 0
                ], [
                    "name": "Witness",
                    "description": "Information gathered from a witness",
                    "color": "#A25278",
                    "id": 1
                ], [
                    "name": "Location",
                    "description": "Detailed information about the scene",
                    "id": 4
                ]]
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                Server.setCurrentEventId(1);
                MageCoreDataFixtures.addUser(userId: "user")
                UserDefaults.standard.currentUserId = "user";
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")
                tester().wait(forTimeInterval: 0.5);
                MageCoreDataFixtures.addEventFromJson(formsJson: formsJson, maxObservationForms: 1, minObservationForms: 1)
                
                let formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mmZ";
                formatter.locale = Locale(identifier: "en_US_POSIX");
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: MockObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                tester().wait(forTimeInterval: 0.5);
                
                coordinator.start();
                
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "Save");
                
                tester().waitForView(withAccessibilityLabel: "VEHICLE")
                tester().waitForAbsenceOfView(withAccessibilityLabel: "SUSPECT")
                
                tester().tapView(withAccessibilityLabel: "Save")
                expect(delegate.editCompleteCalled).to(beTrue())
            }
        }
    }
}
