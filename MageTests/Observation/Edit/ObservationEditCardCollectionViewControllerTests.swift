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
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var observationEditController: ObservationEditCardCollectionViewController!
            var view: UIView!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, usesDrawRect: Bool = false, doneClosure: (() -> Void)?) {
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
                TestHelpers.clearAndSetUpStack();
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);
                window.makeKeyAndVisible();
                                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                UserDefaults.standard.serverMajorVersion = 6;
                UserDefaults.standard.serverMinorVersion = 0;
            }
            
            afterEach {
                tester().waitForAnimationsToFinish();
                waitUntil { done in
                    observationEditController.dismiss(animated: false, completion: {
                        done();
                    });
                }
                window?.resignKey();
                window.rootViewController = nil;
                observationEditController = nil;
                view = nil;
                window = nil;
                TestHelpers.cleanUpStack();
            }
            
            describe("Legacy") {
                beforeEach {
                    print("Legacy set the mage server version");
                    UserDefaults.standard.serverMajorVersion = 5;
                    UserDefaults.standard.serverMinorVersion = 4;
                }
                
                it("empty observation") {
                    var completeTest = false;
                    
                    waitUntil { done in
                        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                    
                    let observation = ObservationBuilder.createBlankObservation(1);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    let delegate = MockObservationEditCardDelegate();
                    observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                    
                    window.rootViewController = observationEditController;
                    view = observationEditController.view;
                    
                    maybeRecordSnapshot(view, usesDrawRect: true, doneClosure: {
                        completeTest = true;
                    })
                    
                    if (recordSnapshots) {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    } else {
                        expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                    }
                }
                
                it("launch gallery") {
                    var completeTest = false;

                    waitUntil { done in
                        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                    
                    let observation = ObservationBuilder.createBlankObservation(1);
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    let delegate = MockObservationEditCardDelegate();
                    observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                    
                    window.rootViewController = observationEditController;
                    view = observationEditController.view;
                    
                    tester().waitForView(withAccessibilityLabel: "attachments Gallery");
                    tester().tapView(withAccessibilityLabel: "attachments Gallery");
                    tester().waitForAnimationsToFinish();
                    tester().wait(forTimeInterval: 1.0);

                    maybeRecordSnapshot(window, usesDrawRect: true, doneClosure: {
                        completeTest = true;
                    })

                    if (recordSnapshots) {
                        expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    } else {
                        expect(window).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                    }
                }
            }
            
            it("empty observation not new") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForAnimationsToFinish();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("empty new observation zero forms") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "zeroForms") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForAnimationsToFinish();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("add form button should call delegate") {
                var completeTest = false;

                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form");
                tester().waitForAnimationsToFinish();
                expect(delegate.addFormCalled).to(beTrue());
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("show the form button if there are two forms") {
                var completeTest = false;

                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                tester().tapView(withAccessibilityLabel: "Add Form");
                tester().waitForAnimationsToFinish();
                expect(delegate.addFormCalled).to(beTrue());
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("not show the add form button if there are no forms") {
                var completeTest = false;

                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "zeroForms") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                tester().waitForAnimationsToFinish();
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("empty new observation two forms should call add form") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                tester().waitForAnimationsToFinish();
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).to(beTrue());
            }
            
            it("when form is added it should show") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoForms") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).to(beTrue());
                tester().waitForAnimationsToFinish();
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation should show current forms") {
                var completeTest = false;
                let formsJsonFile = "twoForms";
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: formsJsonFile) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
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
                tester().waitForAnimationsToFinish();
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation should expand current forms") {
                var completeTest = false;
                let formsJsonFile = "twoForms";
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: formsJsonFile) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
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
                tester().waitForAnimationsToFinish();
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation should show current forms multiple forms") {
                var completeTest = false;
                let formsJsonFile = "twoForms";
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: formsJsonFile) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
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
                tester().waitForAnimationsToFinish();
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation should show all the things form") {
                var completeTest = false;
                let formsJsonFile = "allTheThings";
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: formsJsonFile) { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
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
                tester().waitForAnimationsToFinish();
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation should show checkbox form") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "checkboxForm") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                tester().waitForAnimationsToFinish();
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("filling out the form should update the form header") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).to(beTrue());
                tester().waitForAnimationsToFinish();
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
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("saving the form should send the observation to the delegate") {
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
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

                tester().waitForView(withAccessibilityLabel: "field0");
                print("field0 before entering \(viewTester().usingLabel("field0"))");
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
//                    print("safeObservation \(safeObservation)")
                    let properties: [String: Any] = safeObservation.properties as! [String: Any];
                    let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
//                    print("forms is \(forms)")
                    expect(forms[0]).toNot(beNil());
                    let firstForm = forms[0]
                    expect(firstForm["formId"] as? Int).to(equal(1));
                    expect(firstForm["field1"] as? String).to(equal("Some other text"));
                    expect(firstForm["field0"] as? String).to(equal("The Title"));
//                expect(safeObservation.properties["form"]
                }
            }
            
            it("clearing a field should update the form header") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "twoFormsAlternate") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                
                tester().enterText("The Title", intoViewWithAccessibilityLabel: "field0");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().clearTextFromView(withAccessibilityLabel: "field1")
                tester().tapView(withAccessibilityLabel: "Done");
                tester().waitForAnimationsToFinish();
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            // Can't actually test adding an image from the gallery, because, testing...
            it("should bring up the gallery if the gallery button is tapped") {
                let fieldId = "field23";
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "attachmentForm") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                let delegate = MockObservationEditCardDelegate();
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true, containerScheme: MAGEScheme.scheme());
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
                expect(delegate.addFormCalled).to(beTrue());
                
                if let event: Event = Event.mr_findFirst() {
                    observationEditController.formAdded(form: (event.forms as! [Any])[0] as! [String: Any]);
                }
                tester().tapView(withAccessibilityLabel: fieldId + " Gallery");
                tester().waitForAnimationsToFinish();
                tester().wait(forTimeInterval: 1.0);
                // use draw rect to capture the gallery view as well
                maybeRecordSnapshot(window, usesDrawRect: true, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(window).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
        }
    }
}
