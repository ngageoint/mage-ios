//
//  ObservationFormViewTests.swift
//  MAGE
//
//  Created by Daniel Barela on 5/27/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class ObservationFormViewTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationFormView") {
            let recordSnapshots = false;
            var completeTest = false;

            var controller: UIViewController!
            var window: UIWindow!;
            
            var observation: Observation!;
            var formView: ObservationFormView!
            var view: UIView!
            var eventForm: [String:Any]!
            var form: [String : Any]!
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
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
                completeTest = false;
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);
                
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .white;
                window.makeKeyAndVisible();
                
                eventForm = FormBuilder.createFormWithAllFieldTypes();
                
                form = [ : ];
            }
            
            afterEach {
                tester().waitForAnimationsToFinish();
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.resignKey();
                window = nil;
                TestHelpers.clearAndSetUpStack();
            }
            
            it("no initial values in the observation") {
                observation = ObservationBuilder.createBlankObservation();
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1);

                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("observation filled in completely") {
                observation = ObservationBuilder.createPointObservation();
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1);
                
                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                let fields = eventForm["fields"] as! [[String: Any]];
                
                for field in fields {
                    if let baseFieldView: BaseFieldView = formView.fieldViewForField(field: field) {
                        if let geometryField = baseFieldView as? EditGeometryView {
                            geometryField.setValue(SFPoint(x: -104.3678, andY: 40.1085));
                        } else if let checkboxField = baseFieldView as? EditCheckboxFieldView {
                            checkboxField.setValue(true);
                        } else if let numberField = baseFieldView as? EditNumberFieldView {
                            numberField.setValue("2")
                        } else if let dateField = baseFieldView as? EditDateView {
                            dateField.setValue("2020-11-01T12:00:00.000Z")
                        } else {
                            baseFieldView.setValue("value");
                        }
                    }
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
            
            it("delegate called when field changes and new value is sent") {
                let fieldId = "field8";
                let delegate = MockFieldDelegate();
                observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm);
                let properties = observation.properties as? [String: [[String: Any]]];
                form = properties?["forms"]?[0] ?? [ : ];
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1, delegate: delegate);
                
                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                                
                tester().waitForView(withAccessibilityLabel: fieldId);
                tester().enterText("new text", intoViewWithAccessibilityLabel: fieldId);
                tester().tapView(withAccessibilityLabel: "Done");
                
                expect(delegate.fieldChangedCalled).to(beTrue());
                expect(delegate.newValue as? String).to(equal("new text"));
                
                let newProperties = observation.properties as? [String: [[String: Any]]];
                let newForm: [String: Any] = newProperties?["forms"]?[0] ?? [ : ];
                let field8Value: String = newForm[fieldId] as? String ?? "";
                
                expect(field8Value).to(equal("new text"));
            }
            
            it("delegate called when field is cleared") {
                let fieldId = "field8";
                let delegate = MockFieldDelegate();
                observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm);
                let properties = observation.properties as? [String: [[String: Any]]];
                form = properties?["forms"]?[0] ?? [ : ];
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1, delegate: delegate);
                
                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                tester().waitForView(withAccessibilityLabel: fieldId);
                tester().enterText("not empty", intoViewWithAccessibilityLabel: fieldId);
                tester().waitForTappableView(withAccessibilityLabel: "Done");
                tester().tapView(withAccessibilityLabel: "Done");
                
                expect(delegate.fieldChangedCalled).toEventually(beTrue());
                expect(delegate.newValue as? String).to(equal("not empty"));
                
                delegate.fieldChangedCalled = false;
                
                tester().waitForView(withAccessibilityLabel: fieldId);
                tester().clearTextFromView(withAccessibilityLabel: fieldId);
                tester().waitForTappableView(withAccessibilityLabel: "Done");
                tester().tapView(withAccessibilityLabel: "Done");
                
                expect(delegate.fieldChangedCalled).toEventually(beTrue());
                expect(delegate.newValue as? String).to(beNil());
                                
                let newProperties = observation.properties as? [String: [[String: Any]]];
                let newForm: [String: Any] = newProperties?["forms"]?[0] ?? [ : ];
                expect(newForm[fieldId]).to(beNil());
            }
            
            it("delegate called when geometry field is selected") {
                let fieldId = "field22";
                let delegate = MockFieldDelegate();
                observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm);
                let properties = observation.properties as? [String: [[String: Any]]];
                form = properties?["forms"]?[0] ?? [ : ];
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1, delegate: delegate);
                
                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                tester().waitForView(withAccessibilityLabel: fieldId);
                tester().tapView(withAccessibilityLabel: fieldId);
                
                expect(delegate.fieldSelectedCalled).toEventually(beTrue());
                let selectedField = delegate.selectedField as? [String: Any];
                expect(selectedField?["name"] as? String).to(equal(fieldId));
            }
        }
    }
}
