//
//  ObservationEditCardCollectionViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/21/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class ObservationEditCardCollectionViewControllerTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationEditCardCollectionViewController") {
            let recordSnapshots = false;
            
            var observationEditController: ObservationEditCardCollectionViewController!
            var view: UIView!
            var window: UIWindow!;
            var stackSetup = false;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot(usesDrawRect: true);
                            doneClosure?();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
            beforeEach {
                if (!stackSetup) {
                    window = UIWindow(forAutoLayout: ());
                    window.autoSetDimension(.width, toSize: 300);
                    TestHelpers.clearAndSetUpStack();
                    stackSetup = true;
                }
                Nimble_Snapshots.setNimbleTolerance(0.1);

                MageCoreDataFixtures.clearAllData();
                window.makeKeyAndVisible();
                                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                UserDefaults.standard.serverMajorVersion = 6;
                UserDefaults.standard.serverMinorVersion = 0;
            }
            
            afterEach {
                observationEditController.dismiss(animated: false);
                window.rootViewController = nil;
                observationEditController = nil;
                view = nil;
            }
            
            describe("Legacy") {
                beforeEach {
                    print("Legacy set the mage server version");
                    UserDefaults.standard.serverMajorVersion = 5;
                    UserDefaults.standard.serverMinorVersion = 4;
                }
                
                it("empty observation") {
                    var completeTest = false;
                    
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                    
                    let observation = ObservationBuilder.createBlankObservation(1);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    let delegate = MockObservationEditCardDelegate();
                    observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                    
                    window.rootViewController = observationEditController;
                    view = observationEditController.view;
                    
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                    
                    if (recordSnapshots) {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    } else {
                        expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                    }
                }
                
                it("verify legacy behavior") {
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                    
                    let observation = ObservationBuilder.createBlankObservation(1);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    let delegate = MockObservationEditCardDelegate();
                    observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                    
                    let nc = UINavigationController(rootViewController: observationEditController);
                    window.rootViewController = nc;
                    view = observationEditController.view;
                    
                    tester().waitForView(withAccessibilityLabel: "attachments Gallery");
                    tester().waitForView(withAccessibilityLabel: "Edit Attachment Card")
                    
                    tester().waitForView(withAccessibilityLabel: "Add Form");
                    let addFormButton: MDCFloatingButton = viewTester().usingLabel("Add Form").view as! MDCFloatingButton
                    tester().tapView(withAccessibilityLabel: "Add Form")
                    expect(delegate.addFormCalled).to(beTrue());
                    if let event: Event = Event.mr_findFirst() {
                        observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                    }
                    
                    tester().waitForView(withAccessibilityLabel: "Form 1");
                    
                    // legacy server should only allow one form so add form button should be hidden
                    expect(addFormButton.isHidden).to(beTrue());
                    tester().scrollView(withAccessibilityIdentifier: "card scroll", byFractionOfSizeHorizontal: 0, vertical: -1.0);
                    tester().waitForView(withAccessibilityLabel: "delete form");
                    tester().tapView(withAccessibilityLabel: "delete form");
                    
                    expect(addFormButton.isHidden).to(beFalse());
                    tester().waitForAbsenceOfView(withAccessibilityLabel: "Form 1");
                    
                    // this should fail because there is not a form in the observation
                    tester().tapView(withAccessibilityLabel: "Save")
                    tester().waitForView(withAccessibilityLabel: "One form must be added to this observation");
                    
                    // force add too many forms
                    if let event: Event = Event.mr_findFirst() {
                        observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                        observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                    }
                    
                    tester().tapView(withAccessibilityLabel: "Save")
                    tester().waitForView(withAccessibilityLabel: "Only one form can be added to this observation");
                }
            }
            
            it("empty observation not new") {
                var completeTest = false;
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                
                let nc = UINavigationController(rootViewController: observationEditController);
                
                window.rootViewController = nc;
                view = observationEditController.view;
                
                
                
                expect(observationEditController.title) == "Edit Observation";
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("empty new observation zero forms") {
                var completeTest = false;
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "zeroForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("validation error on observation") {                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "zeroForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                let nc = UINavigationController(rootViewController: observationEditController);
                window.rootViewController = nc;
                view = observationEditController.view;
                
                
                tester().tapView(withAccessibilityLabel: "Save");
                tester().waitForView(withAccessibilityLabel: "The observation has validation errors.");
            }
            
            it("add form button should call delegate") {
                var completeTest = false;

                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form");
                
                expect(delegate.addFormCalled).to(beTrue());
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("show the form button if there are two forms") {
                var completeTest = false;

                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form");
                
                expect(delegate.addFormCalled).to(beTrue());
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("not show the add form button if there are no forms") {
                var completeTest = false;

                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "zeroForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("empty new observation two forms should call add form") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).to(beTrue());
            }
            
            it("when form is added it should show") {
                var completeTest = false;
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
                tester().waitForView(withAccessibilityLabel: "field1 value", value: "None", traits: .none);

                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("user defaults") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let formDefaults = FormDefaults(eventId: 1, formId: 1);
                var defaults = formDefaults.getDefaults() as! [String : AnyHashable];
                defaults["field0"] = "Protest";
                formDefaults.setDefaults(defaults);
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
                
                tester().waitForView(withAccessibilityLabel: "field1 value", value: "", traits: .none);
                tester().waitForView(withAccessibilityLabel: "field0 value", value: "Protest", traits: .none);
            }
            
            it("should undo a deleted form") {
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
                
                tester().scrollView(withAccessibilityIdentifier: "card scroll", byFractionOfSizeHorizontal: 0, vertical: -1.0);
                tester().tapView(withAccessibilityLabel: "delete form")
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Form 1")
                tester().waitForView(withAccessibilityLabel: "UNDO");
                tester().tapView(withAccessibilityLabel: "UNDO");
                tester().waitForView(withAccessibilityLabel: "Form 1")
            }
            
            it("should delete a form") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createPointObservation(eventId: 1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                let nc = UINavigationController(rootViewController: observationEditController);
                
                window.rootViewController = nc;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
                
                tester().scrollView(withAccessibilityIdentifier: "card scroll", byFractionOfSizeHorizontal: 0, vertical: -1.0);
                tester().tapView(withAccessibilityLabel: "delete form")
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Form 1")
                tester().tapView(withAccessibilityLabel: "Save");
                expect(delegate.saveObservationCalled).to(beTrue());
                expect(delegate.observationSaved?.properties?[ObservationKey.forms.key] as? [Any]).to(beEmpty());
            }
            
            it("should reorder forms") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createPointObservation(eventId: 1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                let nc = UINavigationController(rootViewController: observationEditController);
                
                window.rootViewController = nc;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[1] as! [String: Any]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 2")
                
                tester().scrollView(withAccessibilityIdentifier: "card scroll", byFractionOfSizeHorizontal: 0, vertical: 0.5);
                
                let reorderButton: UIButton = viewTester().usingLabel("reorder").view as! UIButton;
                expect(reorderButton.isHidden).to(beFalse());
                expect(reorderButton.isEnabled).to(beTrue());
                tester().tapView(withAccessibilityLabel: "reorder")
                
                expect(delegate.reorderFormsCalled).to(beTrue());
                var obsForms: [[String: Any]] = observation.properties![ObservationKey.forms.key] as! [[String : Any]];
                obsForms.reverse();
                observation.properties![ObservationKey.forms.key] = obsForms;
                observationEditController.formsReordered(observation: observation);
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
                tester().waitForView(withAccessibilityLabel: "Form 2")
                
                tester().tapView(withAccessibilityLabel: "Save");
                expect(delegate.saveObservationCalled).to(beTrue());
                expect(delegate.observationSaved?.properties?[ObservationKey.forms.key] as? [Any]).toNot(beEmpty());
            }
            
            it("cannot add more forms than maxObservationForms or less than minObservationForms") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm", maxObservationForms: 1, minObservationForms: 1)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                let nc = UINavigationController(rootViewController: observationEditController);
                
                window.rootViewController = nc;
                view = observationEditController.view;
                
                // try to save with zero forms, should fail
                tester().waitForTappableView(withAccessibilityLabel: "Save")
                tester().tapView(withAccessibilityLabel: "Save")
                tester().waitForView(withAccessibilityLabel: "Total number of forms in an observation must be at least 1");
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                // reset the delegate
                delegate.addFormCalled = false;
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                let addFormFab: MDCFloatingButton = viewTester().usingLabel("Add Form").view as! MDCFloatingButton;
                // add form button should be enabled but show a message if the user taps it
                expect(addFormFab.isEnabled).to(beTrue());
                
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beFalse());
                tester().tapView(withAccessibilityLabel: "Add Form")
                tester().waitForView(withAccessibilityLabel: "Total number of forms in an observation cannot be more than 1")
                
                // force add another one and save and verify the save does not succeed
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().tapView(withAccessibilityLabel: "Save")
                tester().waitForView(withAccessibilityLabel: "Total number of forms in an observation cannot be more than 1")
                expect(delegate.saveObservationCalled).to(beFalse());
            }
            
            it("must add the proper number of forms specified by the form") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneFormRestricted")
                
                let observation = ObservationBuilder.createPointObservation(eventId: 1)
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                let nc = UINavigationController(rootViewController: observationEditController);
                
                window.rootViewController = nc;
                view = observationEditController.view;
                
                // try to save with zero forms, should fail
                tester().waitForTappableView(withAccessibilityLabel: "Save")
                tester().tapView(withAccessibilityLabel: "Save")
                tester().waitForView(withAccessibilityLabel: "Test form must be included in an observation at least 1 time");
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                // reset the delegate
                delegate.addFormCalled = false;
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                let addFormFab: MDCFloatingButton = viewTester().usingLabel("Add Form").view as! MDCFloatingButton;
                expect(addFormFab.isEnabled).to(beTrue());
                
                // force add another one and save and verify the save does not succeed
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().tapView(withAccessibilityLabel: "Save")
                tester().waitForView(withAccessibilityLabel: "Test form cannot be included in an observation more than 1 time")
                expect(delegate.saveObservationCalled).to(beFalse());
            }
            
            it("observation should show current forms") {
                var completeTest = false;
                let formsJsonFile = "twoForms";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: formsJsonFile)
                
                guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: formsJsonFile, ofType: "json") else {
                    fatalError("\(formsJsonFile).json not found")
                }
                guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
                    fatalError("Unable to convert \(formsJsonFile).json to String")
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    fatalError("Unable to convert \(formsJsonFile).json to Data")
                }
                
                guard let forms : [[String: Any]] = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                    fatalError("Unable to convert \(formsJsonFile).json to JSON dictionary")
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: forms[0], values: [
                    "field0": "At Venue",
                    "field1": "Low"
                ])
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation should expand current forms") {
                var completeTest = false;
                let formsJsonFile = "twoForms";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: formsJsonFile)
                
                guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: formsJsonFile, ofType: "json") else {
                    fatalError("\(formsJsonFile).json not found")
                }
                guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
                    fatalError("Unable to convert \(formsJsonFile).json to String")
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    fatalError("Unable to convert \(formsJsonFile).json to Data")
                }
                
                guard let forms : [[String: Any]] = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                    fatalError("Unable to convert \(formsJsonFile).json to JSON dictionary")
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: forms[0], values: [
                    "field0": "At Venue",
                    "field1": "Low"
                ])
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForView(withAccessibilityLabel: "expand");
                tester().tapView(withAccessibilityLabel: "expand");
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation should show current forms multiple forms") {
                var completeTest = false;
                let formsJsonFile = "twoForms";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: formsJsonFile)
                
                guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: formsJsonFile, ofType: "json") else {
                    fatalError("\(formsJsonFile).json not found")
                }
                guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
                    fatalError("Unable to convert \(formsJsonFile).json to String")
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    fatalError("Unable to convert \(formsJsonFile).json to Data")
                }
                
                guard let forms : [[String: Any]] = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                    fatalError("Unable to convert \(formsJsonFile).json to JSON dictionary")
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: forms[0], values: [
                    "field0": "At Venue",
                    "field1": "Low"
                ])
                
                ObservationBuilder.addFormToObservation(observation: observation, form: forms[0], values: [
                    "field0": "Protest",
                    "field1": "High"
                ])
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation should show all the things form") {
                var completeTest = false;
                let formsJsonFile = "allTheThings";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: formsJsonFile)
                
                guard let pathString = Bundle(for: MageCoreDataFixtures.self).path(forResource: formsJsonFile, ofType: "json") else {
                    fatalError("\(formsJsonFile).json not found")
                }
                guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
                    fatalError("Unable to convert \(formsJsonFile).json to String")
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else {
                    fatalError("Unable to convert \(formsJsonFile).json to Data")
                }
                
                guard let forms : [[String: Any]] = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                    fatalError("Unable to convert \(formsJsonFile).json to JSON dictionary")
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: forms[0], values: [
                    "type": "Parade Event",
                    "field7": "Low"
                ])
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation should show checkbox form") {
                var completeTest = false;
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "checkboxForm")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("filling out the form should update the form header") {
                var completeTest = false;
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().enterText("The Title", intoViewWithAccessibilityLabel: "field0");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().clearText(fromAndThenEnterText: "Some other text", intoViewWithAccessibilityLabel: "field1");
                tester().tapView(withAccessibilityLabel: "Done");
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("saving the form should send the observation to the delegate") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                let navigationController = UINavigationController(rootViewController: observationEditController);
                
                window.rootViewController = navigationController;
                view = observationEditController.view;
                
                tester().waitForView(withAccessibilityLabel: "ObservationEditCardCollection");
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().waitForView(withAccessibilityLabel: "geometry");
                tester().tapView(withAccessibilityLabel: "geometry");
                expect(delegate.launchFieldSelectionViewControllerCalled).to(beTrue());
                expect(delegate.viewControllerToLaunch).toNot(beNil());
                navigationController.pushViewController(delegate.viewControllerToLaunch!, animated: false);
                tester().tapView(withAccessibilityLabel: "Done");

                tester().waitForView(withAccessibilityLabel: "field0");
                tester().enterText("The Title", intoViewWithAccessibilityLabel: "field0");
                TestHelpers.printAllAccessibilityLabelsInWindows();

                tester().waitForFirstResponder(withAccessibilityLabel: "field0");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().clearText(fromAndThenEnterText: "Some other text", intoViewWithAccessibilityLabel: "field1");
                tester().tapView(withAccessibilityLabel: "Done");
                
                tester().tapView(withAccessibilityLabel: "Save");
                expect(delegate.saveObservationCalled).to(beTrue());
                expect(delegate.observationSaved).toNot(beNil());
                if let safeObservation: Observation = delegate.observationSaved {
                    let properties: [String: Any] = safeObservation.properties as! [String: Any];
                    let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
                    expect(forms[0]).toNot(beNil());
                    let firstForm = forms[0]
                    expect(firstForm["formId"] as? Int).to(equal(1));
                    expect(firstForm["field1"] as? String).to(equal("Some other text"));
                    expect(firstForm["field0"] as? String).to(equal("The Title"));
                }
            }
            
            it("clearing a field should update the form header") {
                var completeTest = false;
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().enterText("The Title", intoViewWithAccessibilityLabel: "field0");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().clearTextFromView(withAccessibilityLabel: "field1")
                tester().tapView(withAccessibilityLabel: "Done");
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
        }
    }
}
