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
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot();
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
                
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                window.makeKeyAndVisible();
                                
                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.set(false, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
            }
            
            afterEach {
                tester().waitForAnimationsToFinish();
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.resignKey();
                window = nil;
                TestHelpers.clearAndSetUpStack();
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false);
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: false);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
                window.rootViewController = observationEditController;
                view = observationEditController.view;
                
                tester().waitForTappableView(withAccessibilityLabel: "Add Form");
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
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
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
                observationEditController = ObservationEditCardCollectionViewController(delegate: delegate, observation: observation, newObservation: true);
                
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
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
        }
    }
}
