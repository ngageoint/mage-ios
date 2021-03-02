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

import MagicalRecord

@testable import MAGE

class ObservationEditCoordinatorTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationEditCoordinator") {
            var controller: UINavigationController!
            var window: UIWindow!;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                window = UIWindow(frame: UIScreen.main.bounds);
                window.makeKeyAndVisible();
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                
                controller = UINavigationController();
                window.rootViewController = controller;
                NSDate.setDisplayGMT(true);
            }
            
            afterEach {
                tester().waitForAnimationsToFinish();
                waitUntil { done in
                    if let safePresented = controller.presentedViewController {
                        safePresented.dismiss(animated: false, completion: {
                            controller.dismiss(animated: false, completion: {
                                done();
                            })
                        })
                    } else {
                        controller.dismiss(animated: false, completion: {
                            done();
                        })
                    }
                }
                window?.resignKey();
                window.rootViewController = nil;
                controller = nil;
                window = nil;
                TestHelpers.cleanUpStack();
            }
            
            it("initialize the coordinator with a geometry") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                                
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
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                waitUntil { done in
                
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let observation = ObservationBuilder.createPointObservation(context: localContext);
                        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    }) { (success, error) in
                        done();
                    }
                }
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
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            done();
                        }
                    }
                }
                
                waitUntil { done in
                    
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let observation = ObservationBuilder.createPointObservation(context: localContext);
                        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    }) { (success, error) in
                        done();
                    }
                }
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
                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                waitUntil { done in
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let observation = ObservationBuilder.createPointObservation(eventId: 1, context: localContext);
                        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    }) { (success, error) in
                        done();
                    }
                }
                let observation: Observation! = Observation.mr_findFirst(in: .mr_default());
                
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, observation: observation);
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                coordinator.start();
                                
                tester().expect(viewTester().usingLabel("timestamp").view, toContainText: "April 26, 1970 at 5:46:40 PM GMT")
                
                tester().expect(viewTester().usingLabel("geometry").view, toContainText: "40.00850, -105.26780");
            }
            
            it("should show form chooser with new observation") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());

                coordinator.start();
                
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "Add A Form Table");
                tester().waitForView(withAccessibilityLabel: "Test");
            }
            
            it("should show form chooser with new observation and pick a form") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                coordinator.start();
                                
                tester().waitForView(withAccessibilityLabel: "Test");
                tester().tapView(withAccessibilityLabel: "Test");
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "Form 1")
            }
            
            it("should show form chooser with new observation and pick a form and select a combo field") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: MockObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                coordinator.start();
                
                tester().waitForView(withAccessibilityLabel: "Test");
                tester().tapView(withAccessibilityLabel: "Test");
                
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "field1");
                tester().tapView(withAccessibilityLabel: "field1");
                
                tester().waitForAnimationsToFinish();
                tester().tapRow(at: IndexPath(row: 1, section: 0), inTableViewWithAccessibilityIdentifier: "choices")
                
                tester().tapView(withAccessibilityLabel: "Done");
                tester().waitForAnimationsToFinish();
                
                tester().expect(viewTester().usingLabel("field1")?.view, toContainText: "Low")
            }
            
            it("should show form chooser with new observation and pick a form and select the observation geometry field") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "geometryField") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: MockObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                coordinator.start();
                                
                tester().waitForView(withAccessibilityLabel: "Test");
                tester().tapView(withAccessibilityLabel: "Test");
                
                tester().waitForAnimationsToFinish();
                tester().waitForTappableView(withAccessibilityLabel: "geometry");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().tapView(withAccessibilityLabel: "geometry");
                
                tester().waitForAnimationsToFinish();
                
                tester().waitForView(withAccessibilityLabel: "Latitude");
                tester().clearText(fromAndThenEnterText: "40.1", intoViewWithAccessibilityLabel: "Latitude");
                tester().clearText(fromAndThenEnterText: "-105.26", intoViewWithAccessibilityLabel: "Longitude");
                // need to wait so that the text field can change the geometry.
                // TODO: Fix that
                tester().wait(forTimeInterval: 1.0);
                
                tester().waitForTappableView(withAccessibilityLabel: "Done");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().tapView(withAccessibilityLabel: "Done");
                tester().waitForAnimationsToFinish();
                
                let obsPoint: SFPoint = coordinator.observation?.getGeometry() as! SFPoint;
                expect(obsPoint.y).to(beCloseTo(40.1));
                expect(obsPoint.x).to(beCloseTo(-105.26));
                TestHelpers.printAllAccessibilityLabelsInWindows();
                
                expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "40.10000, -105.26000"
                expect((viewTester().usingLabel("location field1")!.view as! MDCButton).currentTitle) == "NO LOCATION SET"
            }
            
            it("should show form chooser with new observation and pick a form and select a geometry field") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "geometryField") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: MockObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                coordinator.start();
                                
                tester().waitForView(withAccessibilityLabel: "Test");
                tester().tapView(withAccessibilityLabel: "Test");
                
                tester().waitForAnimationsToFinish();
                tester().waitForTappableView(withAccessibilityLabel: "field1");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().tapView(withAccessibilityLabel: "field1");
                
                tester().waitForAnimationsToFinish();
                
                tester().waitForView(withAccessibilityLabel: "Latitude");
                tester().clearText(fromAndThenEnterText: "40.0", intoViewWithAccessibilityLabel: "Latitude");
                tester().clearText(fromAndThenEnterText: "-105.26", intoViewWithAccessibilityLabel: "Longitude");
                // need to wait so that the text field can change the geometry.
                // TODO: Fix that
                tester().wait(forTimeInterval: 1.0);
                
                tester().waitForTappableView(withAccessibilityLabel: "Done");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().tapView(withAccessibilityLabel: "Done");
                tester().waitForAnimationsToFinish();
                
                let forms = (coordinator.observation?.properties!["forms"])! as! [[String: Any]];
                let fieldPoint: SFPoint = forms[0]["field1"] as! SFPoint;
                expect(fieldPoint.y).to(beCloseTo(40.0));
                expect(fieldPoint.x).to(beCloseTo(-105.26));
                
                expect((viewTester().usingLabel("location field1")!.view as! MDCButton).currentTitle) == "40.00000, -105.26000"
                expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "40.00850, -105.26780"
            }
            
            it("should show form chooser with new observation and pick a form and set the observations date") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "geometryField") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
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
                
                tester().waitForAnimationsToFinish();
                tester().waitForTappableView(withAccessibilityLabel: "timestamp");
                tester().tapView(withAccessibilityLabel: "timestamp");
                tester().waitForAnimationsToFinish();
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
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, location: point, accuracy: CLLocationAccuracy(3.2), provider: "GPS", delta: 1.2)
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                
                coordinator.start();
                                
                tester().waitForView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
            }
            
            it("should cancel editing") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            UserDefaults.standard.currentUserId = "user";
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                waitUntil { done in
                    MagicalRecord.save({ (localContext: NSManagedObjectContext) in
                        let observation = ObservationBuilder.createPointObservation(eventId: 1, context: localContext);
                        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    }) { (success, error) in
                        done();
                    }
                }
                let observation: Observation! = Observation.mr_findFirst(in: .mr_default());
                
                let delegate: ObservationEditDelegate = MockObservationEditDelegate();
                
                let coordinator = ObservationEditCoordinator(rootViewController: controller, delegate: delegate, observation: observation);
                coordinator.applyTheme(withContainerScheme: MAGEScheme.scheme());
                coordinator.start();
                                
                tester().waitForView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                tester().waitForView(withAccessibilityLabel: "Discard Changes");
            }
        }
    }
}
