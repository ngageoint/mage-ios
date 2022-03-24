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
import sf_ios
//import Nimble_Snapshots

@testable import MAGE

class ObservationFormViewTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationFormView") {
            var controller: UIViewController!
            var window: UIWindow!;
            
            var observation: Observation!;
            var formView: ObservationFormView!
            var view: UIView!
            var eventForm: Form!
            var form: [String : Any]!

            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .white;
                
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                
                eventForm = FormBuilder.createFormWithAllFieldTypes();
                
                form = [ : ];
//                Nimble_Snapshots.setNimbleTolerance(0.1);
//                Nimble_Snapshots.recordAllSnapshots()
            }
            
            afterEach {
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
                TestHelpers.clearAndSetUpStack();
            }
            
            it("no initial values in the observation") {
                observation = ObservationBuilder.createBlankObservation();
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1, viewController: controller);
                formView.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();

                window.rootViewController = controller;
                controller.view.addSubview(view);
                
//                expect(view).to(haveValidSnapshot());
            }

            it("observation filled in completely") {
                observation = ObservationBuilder.createPointObservation();
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1, viewController: controller);
                formView.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();

                window.rootViewController = controller;
                controller.view.addSubview(view);

                let fields = eventForm!.json!.json!["fields"] as! [[String: Any]];

                for field in fields {
                    if let baseFieldView: BaseFieldView = formView.fieldViewForField(field: field) {
                        if let geometryField = baseFieldView as? GeometryView {
                            geometryField.setValue(SFPoint(x: -104.3678, andY: 40.1085));
                        } else if let checkboxField = baseFieldView as? CheckboxFieldView {
                            checkboxField.setValue(true);
                        } else if let numberField = baseFieldView as? NumberFieldView {
                            numberField.setValue("2")
                        } else if let dateField = baseFieldView as? DateView {
                            dateField.setValue("2020-11-01T12:00:00.000Z")
                        } else {
                            baseFieldView.setValue("value");
                        }
                    }
                }
                tester().waitForAnimationsToFinish();
                tester().wait(forTimeInterval: 7.0);
//                expect(view).to(haveValidSnapshot());
            }

            it("delegate called when field changes and new value is sent") {
                let fieldId = "field8";
                let delegate = MockObservationFormListener();
                observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm!);
                let properties = observation.properties as? [String: [[String: Any]]];
                form = properties?["forms"]?[0] ?? [ : ];
                print("")
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1, viewController: controller, observationFormListener: delegate);
                formView.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();

                window.rootViewController = controller;
                controller.view.addSubview(view);

                tester().waitForView(withAccessibilityLabel: fieldId);
                tester().enterText("new text", intoViewWithAccessibilityLabel: fieldId);
                tester().tapView(withAccessibilityLabel: "Done");

                expect(delegate.formUpdatedCalled).to(beTrue());
                expect(delegate.formUpdatedForm?[fieldId] as? String).to(equal("new text"));

                let newProperties = observation.properties as? [String: [[String: Any]]];
                let newForm: [String: Any] = newProperties?["forms"]?[0] ?? [ : ];
                let field8Value: String = newForm[fieldId] as? String ?? "";

                expect(field8Value).to(equal("new text"));
            }

            it("delegate called when field is cleared") {
                let fieldId = "field8";
                let delegate = MockObservationFormListener();
                observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm!);
                let properties = observation.properties as? [String: [[String: Any]]];
                form = properties?["forms"]?[0] ?? [ : ];
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1, viewController: controller, observationFormListener: delegate);
                formView.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();

                window.rootViewController = controller;
                controller.view.addSubview(view);

                tester().waitForView(withAccessibilityLabel: fieldId);
                tester().enterText("not empty", intoViewWithAccessibilityLabel: fieldId);
                tester().waitForTappableView(withAccessibilityLabel: "Done");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().waitForAbsenceOfSoftwareKeyboard();
                
                expect(delegate.formUpdatedCalled).to(beTrue());
                expect(delegate.formUpdatedForm?[fieldId] as? String).to(equal("not empty"));
                
                delegate.formUpdatedCalled = false;

                tester().waitForView(withAccessibilityLabel: fieldId);
                tester().clearTextFromView(withAccessibilityLabel: fieldId);
                tester().waitForTappableView(withAccessibilityLabel: "Done");
                tester().tapView(withAccessibilityLabel: "Done");

                expect(delegate.formUpdatedCalled).toEventually(beTrue());
                expect(delegate.formUpdatedForm?.index(forKey: fieldId)).to(beNil());
                
                let newProperties = observation.properties as? [String: [[String: Any]]];
                let newForm: [String: Any] = newProperties?["forms"]?[0] ?? [ : ];
                expect(newForm[fieldId]).to(beNil());
            }

            it("delegate called when geometry field is selected") {
                let fieldId = "field22";
                let delegate = MockFieldDelegate();
                observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addFormToObservation(observation: observation, form: eventForm!);
                let properties = observation.properties as? [String: [[String: Any]]];
                form = properties?["forms"]?[0] ?? [ : ];
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1, viewController: controller, delegate: delegate);
                formView.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();

                window.rootViewController = controller;
                controller.view.addSubview(view);

                tester().waitForView(withAccessibilityLabel: fieldId);
                tester().tapView(withAccessibilityLabel: fieldId);

                expect(delegate.launchFieldSelectionViewControllerCalled).toEventually(beTrue());
                expect(delegate.viewControllerToLaunch).to(beAnInstanceOf(GeometryEditViewController.self));
            }
        }
    }
}
