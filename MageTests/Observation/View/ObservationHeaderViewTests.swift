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
            let recordSnapshots = false;
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
                if (controller != nil) {
                    controller.dismiss(animated: false);
                }
                TestHelpers.clearAndSetUpStack();
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                Server.setCurrentEventId(1);
                
                controller = UINavigationController();
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                view = UIView(forAutoLayout: ());
                view.backgroundColor = .systemBackground;
                window.makeKeyAndVisible();
                controller.view.addSubview(view);
                view.autoPinEdgesToSuperviewEdges();
            }
            
            afterEach {
                controller.dismiss(animated: false);
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
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let delegate = MockObservationActionsDelegate();
                let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
                headerView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(headerView);
                headerView.autoPinEdge(toSuperviewEdge: .left);
                headerView.autoPinEdge(toSuperviewEdge: .right);
                headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
                view = headerView;
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "important reason");
                tester().expect(viewTester().usingLabel("important reason").view, toContainText: "This is important")
                tester().waitForView(withAccessibilityLabel: "FLAGGED BY USER ABC");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "USER ABC • 2020-06-05 11:21 MDT");
                tester().waitForView(withAccessibilityLabel: "At Venue");
                tester().waitForView(withAccessibilityLabel: "None");
                tester().waitForView(withAccessibilityLabel: "location geometry")
                expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "40.00850, -105.26780";
                tester().waitForView(withAccessibilityLabel: "1 FAVORITE");
                expect((viewTester().usingLabel("favorite").view as! MDCButton).imageTintColor(for: .normal)).to(be(MDCPalette.green.accent700));
                let importantButton = viewTester().usingLabel("important")?.usingTraits(UIAccessibilityTraits(arrayLiteral: .button)).view as! MDCButton
                expect(importantButton.imageTintColor(for: .normal)).to(be(MDCPalette.orange.accent400));
                
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
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let delegate = MockObservationActionsDelegate();
                let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
                headerView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(headerView);
                headerView.autoPinEdge(toSuperviewEdge: .left);
                headerView.autoPinEdge(toSuperviewEdge: .right);
                headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
                
                view = headerView;
                
                tester().waitForView(withAccessibilityLabel: "directions");
                tester().tapView(withAccessibilityLabel: "directions");
                
                expect(delegate.getDirectionsToObservationsCalled).to(beTrue());
            }
            
            it("tap important button") {
                var completeTest = false;

                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let delegate = MockObservationActionsDelegate();
                let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
                headerView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(headerView);
                headerView.autoPinEdge(toSuperviewEdge: .left);
                headerView.autoPinEdge(toSuperviewEdge: .right);
                headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
                
                view = headerView;
                
                tester().waitForView(withAccessibilityLabel: "important reason");
                tester().expect(viewTester().usingLabel("important reason").view, toContainText: "This is important")
                tester().waitForView(withAccessibilityLabel: "FLAGGED BY USER ABC");
                tester().waitForView(withAccessibilityLabel: "USER ABC • 2020-06-05 11:21 MDT");
                tester().waitForView(withAccessibilityLabel: "At Venue");
                tester().waitForView(withAccessibilityLabel: "None");
                tester().waitForView(withAccessibilityLabel: "location geometry")
                expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "40.00850, -105.26780";
                tester().waitForView(withAccessibilityLabel: "1 FAVORITE");
                expect((viewTester().usingLabel("favorite").view as! MDCButton).imageTintColor(for:.normal)).to(be(MDCPalette.green.accent700));
                let importantButton = viewTester().usingLabel("important")?.usingTraits(UIAccessibilityTraits(arrayLiteral: .button)).view as! MDCButton
                expect(importantButton.imageTintColor(for:.normal)).to(be(MDCPalette.orange.accent400));
                tester().waitForAbsenceOfView(withAccessibilityLabel: "edit important");
                
                tester().waitForView(withAccessibilityLabel: "important");
                tester().tapView(withAccessibilityLabel: "important");
                
                tester().waitForView(withAccessibilityLabel: "edit important");
                tester().expect(viewTester().usingLabel("Important Description").view, toContainText: "This is important");
                tester().clearText(fromAndThenEnterText: "New important!", intoViewWithAccessibilityLabel: "Important Description");
                tester().tapView(withAccessibilityLabel: "Update Important");
                expect(delegate.makeImportantCalled).to(beTrue());
                expect(delegate.makeImportantReason) == "New important!";
                observation.observationImportant?.reason = "New important!";
                headerView.populate(observation: observation);
                tester().expect(viewTester().usingLabel("important reason").view, toContainText: "New important!")
                tester().waitForAbsenceOfView(withAccessibilityLabel: "edit important");
            }
            
            it("tap favorite button") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let delegate = MockObservationActionsDelegate();
                let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
                headerView.applyTheme(withScheme: MAGEScheme.scheme());
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
