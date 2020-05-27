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

class MockNumberFieldDelegate: NSObject, ObservationEditListener {
    var fieldChangedCalled = false;
    var newValue: NSNumber? = nil;
    func observationField(_ field: Any!, valueChangedTo value: Any!, reloadCell reload: Bool) {
        fieldChangedCalled = true;
        newValue = value as? NSNumber;
    }
}

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

class EditNumberFieldViewTests: QuickSpec {
    
    override func spec() {
        
        describe("EditNumberFieldView") {
            
            var numberFieldView: EditNumberFieldView!
            var view: UIView!
            var field: NSMutableDictionary!
            
            beforeEach {
                field = ["title": "Number Field"];
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
            }
            
            it("no initial value") {
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("initial value set") {
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("initial value set with min") {
                field.setValue(2, forKey: FieldKey.min.key);
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("initial value set with max") {
                field.setValue(8, forKey: FieldKey.max.key);
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("initial value set with min and max") {
                field.setValue(2, forKey: FieldKey.min.key);
                field.setValue(8, forKey: FieldKey.max.key);
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("set value later") {
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.setValue( "2")
                expect(view) == snapshot();
            }
            
            it("set valid false") {
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.setValid(false);
                expect(view) == snapshot();
            }
            
            it("set valid true after being invalid") {
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.setValid(false);
                numberFieldView.setValid(true);
                expect(view) == snapshot();
            }
            
            it("required field is invalid if empty") {
                field.setValue(true, forKey: "required");
                numberFieldView = EditNumberFieldView(field: field);
                
                expect(numberFieldView.isEmpty()) == true;
                expect(numberFieldView.isValid(enforceRequired: true)) == false;
            }
            
            it("required field is invalid if text is nil") {
                field.setValue(true, forKey: "required");
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
                field.setValue(true, forKey: "required");
                numberFieldView = EditNumberFieldView(field: field, value: "2");
                
                expect(numberFieldView.isEmpty()) == false;
                expect(numberFieldView.isValid(enforceRequired: true)) == true;
            }
            
            it("required field has title which indicates required") {
                field.setValue(true, forKey: "required");
                numberFieldView = EditNumberFieldView(field: field);
                
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(view) == snapshot();
            }
            
            it("field is not valid if value is below min") {
                field.setValue(2, forKey: FieldKey.min.key);
                field.setValue(8, forKey: FieldKey.max.key);
                numberFieldView = EditNumberFieldView(field: field, value: "1");
                
                expect(numberFieldView.isValid()) == false;
            }
            
            it("field is not valid if value is above max") {
                field.setValue(2, forKey: FieldKey.min.key);
                field.setValue(8, forKey: FieldKey.max.key);
                numberFieldView = EditNumberFieldView(field: field, value: "9");
                
                expect(numberFieldView.isValid()) == false;
            }
            
            it("field is valid if value is between min and max") {
                field.setValue(2, forKey: FieldKey.min.key);
                field.setValue(8, forKey: FieldKey.max.key);
                numberFieldView = EditNumberFieldView(field: field, value: "5");
                
                expect(numberFieldView.isValid()) == true;
            }
            
            it("field is valid if value is above min") {
                field.setValue(2, forKey: FieldKey.min.key);
                numberFieldView = EditNumberFieldView(field: field, value: "5");
                
                expect(numberFieldView.isValid()) == true;
            }
            
            it("field is valid if value is below max") {
                field.setValue(8, forKey: FieldKey.max.key);
                numberFieldView = EditNumberFieldView(field: field, value: "5");
                
                expect(numberFieldView.isValid()) == true;
            }
            
            it("verify only numbers are allowed") {
                let delegate = MockNumberFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(numberFieldView.textField(numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "a")) == false;
                expect(delegate.fieldChangedCalled) == false;
                expect(view) == snapshot();
            }
            
            it("verify if a non number is set it will be invalid") {
                let delegate = MockNumberFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "a";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "2";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == snapshot();
            }
            
            it("verify if number below min is set it will be invalid") {
                field.setValue(2, forKey: FieldKey.min.key);

                let delegate = MockNumberFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "1";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "1";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == snapshot();
            }
            
            it("verify if number above max is set it will be invalid") {
                field.setValue(2, forKey: FieldKey.max.key);
                
                let delegate = MockNumberFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "3";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "3";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == snapshot();
            }
            
            it("verify if number too low is set it will be invalid") {
                field.setValue(2, forKey: FieldKey.min.key);
                field.setValue(8, forKey: FieldKey.max.key);

                let delegate = MockNumberFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "1";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "1";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == snapshot();
            }
            
            it("verify if number too high is set it will be invalid") {
                field.setValue(2, forKey: FieldKey.min.key);
                field.setValue(8, forKey: FieldKey.max.key);
                
                let delegate = MockNumberFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "9";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "9";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == snapshot();
            }
            
            it("test delegate") {
                let delegate = MockNumberFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
               
                numberFieldView.textField.text = "5";
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue) == 5;
                expect(view) == snapshot();
            }
            
            it("allow canceling") {
                let delegate = MockNumberFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                
                numberFieldView.textField.text = "4";
                numberFieldView.cancelButtonPressed();
                expect(delegate.fieldChangedCalled) == false;
                expect(numberFieldView.textField.text) == "2";
                expect(numberFieldView.getValue() as? NSNumber) == 2;
                expect(view) == snapshot();
            }
            
            it("done button should change value") {
                let delegate = MockNumberFieldDelegate()
                numberFieldView = EditNumberFieldView(field: field, delegate: delegate, value: "2");
                view.addSubview(numberFieldView)
                numberFieldView.autoPinEdgesToSuperviewEdges();
                numberFieldView.textField.text = "4";
                numberFieldView.doneButtonPressed();
                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
                expect(numberFieldView.textField.text) == "4";
                expect(numberFieldView.getValue() as? NSNumber) == 4;
                expect(view) == snapshot();
            }
        }
    }
}
