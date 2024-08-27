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

@testable import MAGE
import CoreData

class ObservationEditCardCollectionViewControllerTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("ObservationEditCardCollectionViewController") {
            var observationEditController: ObservationEditCardCollectionViewController!
            var window: UIWindow!;
            var stackSetup = false;
            
            beforeEach {
                if (!stackSetup) {
                    TestHelpers.clearAndSetUpStack();
                    stackSetup = true;
                }
                window = TestHelpers.getKeyWindowVisible();
                TestHelpers.resetUserDefaults();

                MageCoreDataFixtures.clearAllData();
                                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                UserDefaults.standard.serverMajorVersion = 6;
                UserDefaults.standard.serverMinorVersion = 0;
            }
            
            afterEach {
                observationEditController.dismiss(animated: false);
                window.rootViewController = nil;
                observationEditController = nil;
            }
            
            describe("Legacy") {
                beforeEach {
                    print("Legacy set the mage server version");
                    UserDefaults.standard.serverMajorVersion = 5;
                    UserDefaults.standard.serverMinorVersion = 4;
                }
                
                it("empty observation") {
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                    
                    let observation = ObservationBuilder.createBlankObservation(1);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    let delegate = MockObservationEditCardDelegate();
                    observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                    
                    window.rootViewController = observationEditController;
                }
                
                it("verify legacy behavior") {
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                    
                    let observation = ObservationBuilder.createBlankObservation(1);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    let delegate = MockObservationEditCardDelegate();
                    observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                    
                    let nc = UINavigationController(rootViewController: observationEditController);
                    window.rootViewController = nc;
                    
                    tester().waitForView(withAccessibilityLabel: "attachments Gallery");
                    tester().waitForView(withAccessibilityLabel: "Edit Attachment Card")
                    
                    tester().waitForView(withAccessibilityLabel: "Add Form");
                    let addFormButton: MDCFloatingButton = viewTester().usingLabel("Add Form").view as! MDCFloatingButton
                    tester().tapView(withAccessibilityLabel: "Add Form")
                    expect(delegate.addFormCalled).to(beTrue());
                    if let event: Event = Event.mr_findFirst() {
                        observationEditController.formAdded(form: (event.forms!)[0]);
                    }
                    
                    tester().waitForView(withAccessibilityLabel: "Form 1");
                    
                    // legacy server should only allow one form so add form button should be hidden
                    expect(addFormButton.isHidden).to(beTrue());
                    tester().scrollView(withAccessibilityIdentifier: "card scroll", byFractionOfSizeHorizontal: 0, vertical: -1.0);
                    tester().waitForView(withAccessibilityLabel: "Delete Form");
                    tester().tapView(withAccessibilityLabel: "Delete Form");
                    
                    expect(addFormButton.isHidden).to(beFalse());
                    tester().waitForAbsenceOfView(withAccessibilityLabel: "Form 1");
                    
                    // this should fail because there is not a form in the observation
                    tester().tapView(withAccessibilityLabel: "Save")
                    tester().waitForView(withAccessibilityLabel: "One form must be added to this observation");
                    
                    // force add too many forms
                    if let event: Event = Event.mr_findFirst() {
                        observationEditController.formAdded(form: (event.forms!)[0]);
                        observationEditController.formAdded(form: (event.forms!)[0]);
                    }
                    
                    tester().tapView(withAccessibilityLabel: "Save")
                    tester().waitForView(withAccessibilityLabel: "Only one form can be added to this observation");
                }
            }
            
            it("empty observation not new") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                
                let nc = UINavigationController(rootViewController: observationEditController);
                
                window.rootViewController = nc;
                
                tester().waitForView(withAccessibilityLabel: "Save")
                expect(observationEditController.title) == "Edit Observation";
            }
            
            it("empty new observation zero forms") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "zeroForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
            }
            
            it("validation error on observation") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "zeroForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                let nc = UINavigationController(rootViewController: observationEditController);
                window.rootViewController = nc;
                
                tester().tapView(withAccessibilityLabel: "Save");
                tester().waitForView(withAccessibilityLabel: "The observation has validation errors.");
            }
            
            it("add form button should call delegate") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form");
                
                expect(delegate.addFormCalled).toEventually(beTrue());
            }
            
            it("show the form button if there are two forms") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form");
                
                expect(delegate.addFormCalled).to(beTrue());
//                expect(view).to(haveValidSnapshot(usesDrawRect: true));
            }
            
            it("not show the add form button if there are no forms") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "zeroForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
//                expect(view).to(haveValidSnapshot(usesDrawRect: true));
            }
            
            it("empty new observation two forms should call add form") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).to(beTrue());
            }
            
            it("when form is added it should show") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
                tester().waitForView(withAccessibilityLabel: "field1 value", value: "None", traits: .none);
//                expect(view).to(haveValidSnapshot(usesDrawRect: true));
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
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
                
                tester().waitForView(withAccessibilityLabel: "field1 value", value: "Level *", traits: .none);
                tester().waitForView(withAccessibilityLabel: "field0 value", value: "Protest", traits: .none);
            }
            
            it("should undo a deleted form") {
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                tester().waitForAnimationsToFinish()
                tester().waitForView(withAccessibilityLabel: "Form 1")
                
                tester().scrollView(withAccessibilityIdentifier: "card scroll", byFractionOfSizeHorizontal: 0, vertical: -1.0);
                tester().tapView(withAccessibilityLabel: "Delete Form")
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
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 1")

                tester().waitForTappableView(withAccessibilityLabel: "Add Form")
                let addFormButton: UIButton = viewTester().usingLabel("Add Form").view as! UIButton
                addFormButton.removeFromSuperview()
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Add Form")
                tester().waitForTappableView(withAccessibilityLabel: "Delete Form")
                tester().tapView(withAccessibilityLabel: "Delete Form")
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
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                tester().waitForView(withAccessibilityLabel: "Form 1")
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[1]);
                }
                tester().waitForView(withAccessibilityLabel: "Form 2")
                
                let reorderButton: UIButton = viewTester().usingIdentifier("reorder").view as! UIButton;
                expect(reorderButton.isHidden).to(beFalse());
                expect(reorderButton.isEnabled).to(beTrue());
                tester().waitForTappableView(withAccessibilityLabel: "reorder")
                tester().waitForAnimationsToFinish();

                reorderButton.tap()
                
                expect(delegate.reorderFormsCalled).toEventually(beTrue());
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
                    observationEditController.formAdded(form: (event.forms!)[0]);
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
                    observationEditController.formAdded(form: (event.forms!)[0]);
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
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                let addFormFab: MDCFloatingButton = viewTester().usingLabel("Add Form").view as! MDCFloatingButton;
                expect(addFormFab.isEnabled).to(beTrue());
                
                // force add another one and save and verify the save does not succeed
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                tester().tapView(withAccessibilityLabel: "Save")
                tester().waitForView(withAccessibilityLabel: "Test form cannot be included in an observation more than 1 time")
                expect(delegate.saveObservationCalled).to(beFalse());
            }
            
            it("observation should show current forms") {
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
                
                guard let formsJson : [[String: Any]] = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                    fatalError("Unable to convert \(formsJsonFile).json to JSON dictionary")
                }
                
                let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: NSManagedObjectContext.mr_default())
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: forms[0], values: [
                    "field0": "At Venue",
                    "field1": "Low"
                ])
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
            }
            
            it("observation should expand current forms") {
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
                
                guard let formsJson : [[String: Any]] = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                    fatalError("Unable to convert \(formsJsonFile).json to JSON dictionary")
                }
                
                let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: NSManagedObjectContext.mr_default())
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: forms[0], values: [
                    "field0": "At Venue",
                    "field1": "Low"
                ])
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                
                tester().waitForView(withAccessibilityLabel: "expand");
                tester().tapView(withAccessibilityLabel: "expand");
                tester().waitForAnimationsToFinish();
            }
            
            it("observation should show current forms multiple forms") {
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
                
                guard let formsJson : [[String: Any]] = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                    fatalError("Unable to convert \(formsJsonFile).json to JSON dictionary")
                }
                
                let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: NSManagedObjectContext.mr_default())
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
            }
            
            it("observation should show all the things form") {
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
                
                guard let formsJson : [[String: Any]] = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] else {
                    fatalError("Unable to convert \(formsJsonFile).json to JSON dictionary")
                }
                
                let forms = Form.deleteAndRecreateForms(eventId: 1, formsJson: formsJson, context: NSManagedObjectContext.mr_default())
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                ObservationBuilder.addFormToObservation(observation: observation, form: forms[0], values: [
                    "type": "Parade Event",
                    "field7": "Low"
                ])
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
            }
            
            it("observation should show checkbox form") {
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "checkboxForm")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
            }
            
            it("filling out the form should update the form header") {
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                tester().enterText("The Title", intoViewWithAccessibilityLabel: "field0");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().clearText(fromAndThenEnterText: "Some other text", intoViewWithAccessibilityLabel: "field1");
                tester().tapView(withAccessibilityLabel: "Done");
            }
            
            it("saving the form should send the observation to the delegate") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                let navigationController = UINavigationController(rootViewController: observationEditController);
                
                window.rootViewController = navigationController;
                
                tester().waitForView(withAccessibilityLabel: "ObservationEditCardCollection");
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).toEventually(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                tester().waitForView(withAccessibilityLabel: "geometry");
                tester().tapView(withAccessibilityLabel: "geometry");
                expect(delegate.launchFieldSelectionViewControllerCalled).to(beTrue());
                expect(delegate.viewControllerToLaunch).toNot(beNil());
                navigationController.pushViewController(delegate.viewControllerToLaunch!, animated: false);
                viewTester().usingLabel("Geometry Edit Map").longPress();
                tester().tapView(withAccessibilityLabel: "Apply");

                tester().waitForView(withAccessibilityLabel: "field0");
                tester().enterText("The Title", intoViewWithAccessibilityLabel: "field0");

                tester().waitForFirstResponder(withAccessibilityLabel: "field0");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().clearText(fromAndThenEnterText: "Some other text", intoViewWithAccessibilityLabel: "field1");
                tester().tapView(withAccessibilityLabel: "Done");
                
                expect(observationEditController.checkObservationValidity()).to(beTrue());

                tester().tapView(withAccessibilityLabel: "Save");
                expect(delegate.saveObservationCalled).to(beTrue());
                expect(delegate.observationSaved).toNot(beNil());
                if let observation: Observation = delegate.observationSaved {
                    let properties: [String: Any] = observation.properties as! [String: Any];
                    let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
                    expect(forms[0]).toNot(beNil());
                    let firstForm = forms[0]
                    expect(firstForm["formId"] as? Int).to(equal(1));
                    expect(firstForm["field1"] as? String).to(equal("Some other text"));
                    expect(firstForm["field0"] as? String).to(equal("The Title"));
                }
            }
            
            it("saving an invalid form should not send the observation to the delegate") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                let navigationController = UINavigationController(rootViewController: observationEditController);
                
                window.rootViewController = navigationController;
                
                tester().waitForView(withAccessibilityLabel: "ObservationEditCardCollection");
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).toEventually(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                
                tester().waitForView(withAccessibilityLabel: "geometry");
                tester().tapView(withAccessibilityLabel: "geometry");
                expect(delegate.launchFieldSelectionViewControllerCalled).to(beTrue());
                expect(delegate.viewControllerToLaunch).toNot(beNil());
                navigationController.pushViewController(delegate.viewControllerToLaunch!, animated: false);
                tester().tapView(withAccessibilityLabel: "Apply");
                
                tester().waitForView(withAccessibilityLabel: "field0");
                tester().enterText("The Title", intoViewWithAccessibilityLabel: "field0");

                
                tester().waitForFirstResponder(withAccessibilityLabel: "field0");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().clearText(fromAndThenEnterText: "Some other text", intoViewWithAccessibilityLabel: "field1");
                tester().tapView(withAccessibilityLabel: "Done");
                
                tester().tapView(withAccessibilityLabel: "Save");
                expect(observationEditController.checkObservationValidity()).to(beFalse());
                expect(delegate.saveObservationCalled).to(beFalse());
                expect(delegate.observationSaved).to(beNil());
            }
            
            it("clearing a field should update the form header") {
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate")
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form")
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms!)[0]);
                }
                tester().setText("The Title", intoViewWithAccessibilityLabel: "field0")
                tester().setText("", intoViewWithAccessibilityLabel: "field1");
                (viewTester().usingLabel("Field View field0").view as? TextFieldView)?.textFieldDidEndEditing(viewTester().usingLabel("field0").view as! UITextField)
                (viewTester().usingLabel("Field View field1").view as? TextFieldView)?.textFieldDidEndEditing(viewTester().usingLabel("field1").view as! UITextField)
            }
        }
    }
}
