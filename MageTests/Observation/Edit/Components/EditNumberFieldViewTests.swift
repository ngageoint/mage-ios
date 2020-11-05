//
//  EditNumberFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/26/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

extension UITextField {
    func setTextAndSendEvent(_ text: String) {
        self.sendActions(for: .editingDidBegin)
        self.text = text
        self.sendActions(for: .editingChanged)
    }
    
    func endEditingAndSendEvent() {
        self.sendActions(for: .editingDidEnd);
    }
}

class EditNumberFieldViewTests: KIFSpec {
    
    override func spec() {
        
        describe("EditNumberFieldView") {
            
            var numberFieldView: EditNumberFieldView!
            var field: [String: Any]!
            
            let recordSnapshots = false;
            
            var view: UIView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            func maybeSnapshot() -> Snapshot {
                if (recordSnapshots) {
                    return recordSnapshot()
                } else {
                    return snapshot()
                }
            }
            
            beforeEach {
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);
                
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .white;
                window.makeKeyAndVisible();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
            
                field = [
                    "title": "Number Field",
                    "name": "field8",
                    "id": 8
                ];
            }
            
            it("no initial value") {
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == maybeSnapshot()
            }
            
            it("initial value set") {
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == maybeSnapshot();
            }
            
            it("set value via input") {
                let delegate = MockFieldDelegate();
                
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().enterText("2", intoViewWithAccessibilityLabel: field["name"] as? String);
                tester().tapView(withAccessibilityLabel: "Done");
                
                expect(delegate.fieldChangedCalled).to(beTrue());
                
                expect(view) == maybeSnapshot();
            }
            
            it("initial value set with min") {
                field[FieldKey.min.key] = 2;
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == maybeSnapshot();
            }
            
            it("initial value set with max") {
                field[FieldKey.max.key] = 8;
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == maybeSnapshot();
            }
            
            it("initial value set with min and max") {
                field[FieldKey.min.key] = 2;
                field[FieldKey.max.key] = 8;
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == maybeSnapshot();
            }
            
            it("set value later") {
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.setValue( "2")
                expect(view) == maybeSnapshot();
            }
            
            it("set valid false") {
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.setValid(false);
                expect(view) == maybeSnapshot();
            }
            
            it("set valid true after being invalid") {
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.setValid(false);
                numberFieldView.setValid(true);
                expect(view) == maybeSnapshot();
            }
            
            it("required field is invalid if empty") {
                field[FieldKey.required.key] = true;
                numberFieldView = EditNumberFieldView(field: field);
                
                expect(numberFieldView.isEmpty()) == true;
                expect(numberFieldView.isValid(enforceRequired: true)) == false;
            }
            
            it("required field is invalid if text is nil") {
                field[FieldKey.required.key] = true;
                numberFieldView = EditNumberFieldView(field: field);
                numberFieldView.textField.text = nil;
                expect(numberFieldView.isEmpty()) == true;
                expect(numberFieldView.isValid(enforceRequired: true)) == false;
            }
            
            it("field is invalid if text is a letter") {
                numberFieldView = EditNumberFieldView(field: field);
                numberFieldView.textField.text = "a";
                expect(numberFieldView.isEmpty()) == false;
                expect(numberFieldView.isValid(enforceRequired: true)) == false;
            }
            
            it("field should allow changing text to a valid number") {
                numberFieldView = EditNumberFieldView(field: field);
                numberFieldView.textField.text = "1";
                expect(numberFieldView.textField(numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "2")) == true;
                expect(numberFieldView.isEmpty()) == false;
            }
            
            it("field should allow changing text to a blank") {
                numberFieldView = EditNumberFieldView(field: field);
                numberFieldView.textField.text = "1";
                expect(numberFieldView.textField(numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "")) == true;
            }
            
            it("required field is valid if not empty") {
                field[FieldKey.required.key] = true;
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                expect(numberFieldView.isEmpty()) == false;
                expect(numberFieldView.isValid(enforceRequired: true)) == true;
            }
            
            it("required field has title which indicates required") {
                field[FieldKey.required.key] = true;
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(view) == maybeSnapshot();
            }
            
            it("field is not valid if value is below min") {
                field[FieldKey.min.key] = 2;
                field[FieldKey.max.key] = 8;
                numberFieldView = EditNumberFieldView(field: field, value: "1");
                
                expect(numberFieldView.isValid()) == false;
            }
            
            it("field is not valid if value is above max") {
                field[FieldKey.min.key] = 2;
                field[FieldKey.max.key] = 8;
                numberFieldView = EditNumberFieldView(field: field, value: "9");
                
                expect(numberFieldView.isValid()) == false;
            }
            
            it("field is valid if value is between min and max") {
                field[FieldKey.min.key] = 2;
                field[FieldKey.max.key] = 8;
                numberFieldView = EditNumberFieldView(field: field, value: "5");
                
                expect(numberFieldView.isValid()) == true;
            }
            
            it("field is valid if value is above min") {
                field[FieldKey.min.key] = 2;
                numberFieldView = EditNumberFieldView(field: field, value: "5");
                
                expect(numberFieldView.isValid()) == true;
            }
            
            it("field is valid if value is below max") {
                field[FieldKey.max.key] = 8;
                numberFieldView = EditNumberFieldView(field: field, value: "5");
                
                expect(numberFieldView.isValid()) == true;
            }
            
            it("verify only numbers are allowed") {
                let delegate = MockFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(numberFieldView.textField(numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "a")) == false;
                expect(delegate.fieldChangedCalled) == false;
                expect(view) == maybeSnapshot();
            }
            
            it("verify if a non number is set it will be invalid") {
                let delegate = MockFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "a";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "2";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == maybeSnapshot();
            }
            
            it("verify if number below min is set it will be invalid") {
                field[FieldKey.min.key] = 2;

                let delegate = MockFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "1";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "1";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == maybeSnapshot();
            }
            
            it("verify if number above max is set it will be invalid") {
                field[FieldKey.max.key] = 2;

                let delegate = MockFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "3";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "3";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == maybeSnapshot();
            }
            
            it("verify if number too low is set it will be invalid") {
                field[FieldKey.min.key] = 2;
                field[FieldKey.max.key] = 8;

                let delegate = MockFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "1";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "1";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == maybeSnapshot();
            }
            
            it("verify if number too high is set it will be invalid") {
                field[FieldKey.min.key] = 2;
                field[FieldKey.max.key] = 8;
                
                let delegate = MockFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "9";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "9";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == maybeSnapshot();
            }
            
            it("test delegate") {
                let delegate = MockFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
               
                numberFieldView.textField.text = "5";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? NSNumber) == 5;
                expect(view) == maybeSnapshot();
            }
            
            it("allow canceling") {
                let delegate = MockFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "4";
                numberFieldView.cancelButtonPressed();
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "2";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == maybeSnapshot();
            }
            
            it("done button should change value") {
                let delegate = MockFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                numberFieldView.textField.text = "4";
                numberFieldView.doneButtonPressed();
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
                expect(numberFieldView.textField.text) == "4";
                expect(numberFieldView.getValue() as? NSNumber) == 4;
                expect(view) == maybeSnapshot();
            }
        }
    }
}
