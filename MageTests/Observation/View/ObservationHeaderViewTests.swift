//
//  ObservationHeaderViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/23/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import OHHTTPStubs

@testable import MAGE

class ObservationHeaderViewTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationHeaderViewTests") {
            let recordSnapshots = true;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var controller: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, usesDrawRect: Bool = true, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot(usesDrawRect: usesDrawRect);
                            doneClosure?();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
            beforeEach {
                tester().waitForAnimationsToFinish();
                if (controller != nil) {
                    waitUntil { done in
                        controller.dismiss(animated: false, completion: {
                            done();
                        });
                    }
                }
                TestHelpers.clearAndSetUpStack();
                window = UIWindow(frame: UIScreen.main.bounds);
                window.makeKeyAndVisible();
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                Server.setCurrentEventId(1);
                
                controller = UINavigationController();
                window.rootViewController = controller;
                view = UIView(forAutoLayout: ());
                view.backgroundColor = .systemBackground;
                window.makeKeyAndVisible();
                controller.view.addSubview(view);
                view.autoPinEdgesToSuperviewEdges();
            }
            
            afterEach {
                tester().waitForAnimationsToFinish();
                waitUntil { done in
                    controller.dismiss(animated: false, completion: {
                        done();
                    });
                }
                window?.resignKey();
                window.rootViewController = nil;
                controller = nil;
                view = nil;
                window = nil;
                TestHelpers.cleanUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("initialize the ObservationHeaderView") {
                var completeTest = false;
                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                
                                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)  { (success: Bool, error: Error?) in
                                    done();
                                }
                            }
                        }
                    }
                }
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let delegate = MockObservationActionsDelegate();
                let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
                view.addSubview(headerView);
                headerView.autoPinEdge(toSuperviewEdge: .left);
                headerView.autoPinEdge(toSuperviewEdge: .right);
                headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
                view = headerView;
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Invalid snapshot")
                }
            }
            
            it("tap directions button") {
                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                
                                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)  { (success: Bool, error: Error?) in
                                    done();
                                }
                            }
                        }
                    }
                }
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let delegate = MockObservationActionsDelegate();
                let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
                view.addSubview(headerView);
                headerView.autoPinEdge(toSuperviewEdge: .left);
                headerView.autoPinEdge(toSuperviewEdge: .right);
                headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
                
                view = headerView;
                
                tester().waitForView(withAccessibilityLabel: "directions");
                tester().tapView(withAccessibilityLabel: "directions");
                
                expect(delegate.getDirectionsCalled).to(beTrue());
            }
            
            it("tap important button") {
                var completeTest = false;

                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                
                                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)  { (success: Bool, error: Error?) in
                                    done();
                                }
                            }
                        }
                    }
                }
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let delegate = MockObservationActionsDelegate();
                let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
                view.addSubview(headerView);
                headerView.autoPinEdge(toSuperviewEdge: .left);
                headerView.autoPinEdge(toSuperviewEdge: .right);
                headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
                
                view = headerView;
                
                tester().waitForView(withAccessibilityLabel: "important");
                tester().tapView(withAccessibilityLabel: "important");
                
                expect(delegate.makeImportantCalled).to(beTrue());
                
                tester().waitForAnimationsToFinish();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Invalid snapshot")
                }
            }
            
            it("tap favorite button") {
                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                
                                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)  { (success: Bool, error: Error?) in
                                    done();
                                }
                            }
                        }
                    }
                }
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let delegate = MockObservationActionsDelegate();
                let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
                view.addSubview(headerView);
                headerView.autoPinEdge(toSuperviewEdge: .left);
                headerView.autoPinEdge(toSuperviewEdge: .right);
                headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
                
                view = headerView;
                
                tester().waitForView(withAccessibilityLabel: "favorite");
                tester().tapView(withAccessibilityLabel: "favorite");
                
                expect(delegate.favoriteCalled).to(beTrue());
            }
        }
    }
}
