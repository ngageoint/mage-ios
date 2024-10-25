//
//  NumberFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/26/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots

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

//class NumberFieldViewTests: KIFSpec {
//    
//    override func spec() {
//        
//        xdescribe("NumberFieldView") {
//            
//            var numberFieldView: NumberFieldView!
//            var field: [String: Any]!
//                        
//            var view: UIView!
//            var controller: UIViewController!
//            var window: UIWindow!;
//            
//            controller = UIViewController();
//            view = UIView(forAutoLayout: ());
//            view.autoSetDimension(.width, toSize: 300);
//            view.backgroundColor = .white;
//
//            controller.view.addSubview(view);
//            
//            beforeEach {
//                window = TestHelpers.getKeyWindowVisible();
//
//                controller = UIViewController();
//                view = UIView(forAutoLayout: ());
//                view.autoSetDimension(.width, toSize: 300);
//                view.backgroundColor = .white;
//                
//                window.rootViewController = controller;
//                controller.view.addSubview(view);
//            
//                field = [
//                    "title": "Number Field",
//                    "name": "field8",
//                    "id": 8
//                ];
////                Nimble_Snapshots.setNimbleTolerance(0.0);
////                Nimble_Snapshots.recordAllSnapshots()
//            }
//            
//            afterEach {
//                for subview in view.subviews {
//                    subview.removeFromSuperview();
//                }
//            }
//            
//            it("edit mode reference image") {
//                field[FieldKey.min.key] = 2;
//                field[FieldKey.required.key] = true;
//                numberFieldView = NumberFieldView(field: field, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.textField.placeholder) == "Number Field *"
//                expect(numberFieldView.textField.leadingAssistiveLabel.text) == "Must be greater than 2 "
//                expect(numberFieldView.titleLabel.text) == "Must be greater than 2 "
//                
////                expect(view).to(haveValidSnapshot());
//            }
//            
//            it("no initial value") {
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.fieldValue.text).to(beNil());
//                expect(numberFieldView.textField.text) == "";
//                expect(numberFieldView.fieldNameLabel.text) == "Number Field"
//            }
//            
//            it("initial value set") {
//                numberFieldView = NumberFieldView(field: field, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.fieldNameLabel.text) == "Number Field"
//            }
//            
//            it("set value via input") {
//                let delegate = MockFieldDelegate();
//                
//                numberFieldView = NumberFieldView(field: field, delegate: delegate);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField.text) == "";
//                
//                tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
//                tester().enterText("2", intoViewWithAccessibilityLabel: field[FieldKey.name.key] as? String);
//                tester().tapView(withAccessibilityLabel: "Done");
//                
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.fieldNameLabel.text) == "Number Field"
//                
//                expect(delegate.fieldChangedCalled).to(beTrue());
//            }
//            
//            it("initial value set with min") {
//                field[FieldKey.min.key] = 2;
//                numberFieldView = NumberFieldView(field: field, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.textField.placeholder) == "Number Field"
//                expect(numberFieldView.textField.leadingAssistiveLabel.text) == "Must be greater than 2 "
//                expect(numberFieldView.titleLabel.text) == "Must be greater than 2 "
//            }
//            
//            it("initial value set with max") {
//                field[FieldKey.max.key] = 8;
//                numberFieldView = NumberFieldView(field: field, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.textField.placeholder) == "Number Field"
//                expect(numberFieldView.textField.leadingAssistiveLabel.text) == "Must be less than 8"
//                expect(numberFieldView.titleLabel.text) == "Must be less than 8"
//            }
//            
//            it("initial value set with min and max") {
//                field[FieldKey.min.key] = 2;
//                field[FieldKey.max.key] = 8;
//                numberFieldView = NumberFieldView(field: field, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.textField.placeholder) == "Number Field"
//                expect(numberFieldView.textField.leadingAssistiveLabel.text) == "Must be between 2 and 8"
//                expect(numberFieldView.titleLabel.text) == "Must be between 2 and 8"
//            }
//            
//            it("set value later") {
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField.text) == "";
//                
//                numberFieldView.setValue("2")
//                
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.fieldNameLabel.text) == "Number Field"
//            }
//            
//            it("set valid false") {
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                numberFieldView.setValid(false);
//                
//                expect(numberFieldView.textField.text) == "";
//                expect(numberFieldView.textField.placeholder) == "Number Field"
//                expect(numberFieldView.textField.leadingAssistiveLabel.text) == "Must be a number"
////                expect(view).to(haveValidSnapshot());
//            }
//            
//            it("set valid true after being invalid") {
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField.text) == "";
//                expect(numberFieldView.textField.placeholder) == "Number Field"
//                expect(numberFieldView.textField.leadingAssistiveLabel.text) == " ";
//                numberFieldView.setValid(false);
//                expect(numberFieldView.textField.leadingAssistiveLabel.text) == "Must be a number"
//                numberFieldView.setValid(true);
//                expect(numberFieldView.textField.leadingAssistiveLabel.text).to(beNil());
//            }
//            
//            it("required field is invalid if empty") {
//                field[FieldKey.required.key] = true;
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                expect(numberFieldView.isEmpty()) == true;
//                expect(numberFieldView.isValid(enforceRequired: true)) == false;
//                
//                expect(numberFieldView.textField.text) == "";
//                expect(numberFieldView.textField.placeholder) == "Number Field *"
//            }
//            
//            it("required field is invalid if text is nil") {
//                field[FieldKey.required.key] = true;
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                numberFieldView.textField.text = nil;
//                expect(numberFieldView.isEmpty()) == true;
//                expect(numberFieldView.isValid(enforceRequired: true)) == false;
//                expect(numberFieldView.textField.placeholder) == "Number Field *"
//            }
//            
//            it("field is invalid if text is a letter") {
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                numberFieldView.textField.text = "a";
//                expect(numberFieldView.isEmpty()) == false;
//                expect(numberFieldView.isValid(enforceRequired: true)) == false;
//                expect(numberFieldView.textField.placeholder) == "Number Field"
//            }
//            
//            it("field should allow changing text to a valid number") {
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                numberFieldView.textField.text = "1";
//                expect(numberFieldView.textField(numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "2")) == true;
//                expect(numberFieldView.isEmpty()) == false;
//            }
//            
//            it("field should allow changing text to a blank") {
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                numberFieldView.textField.text = "1";
//                expect(numberFieldView.textField(numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "")) == true;
//            }
//            
//            it("required field is valid if not empty") {
//                field[FieldKey.required.key] = true;
//                numberFieldView = NumberFieldView(field: field, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                expect(numberFieldView.isEmpty()) == false;
//                expect(numberFieldView.isValid(enforceRequired: true)) == true;
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.textField.placeholder) == "Number Field *"
//            }
//            
//            it("required field has title which indicates required") {
//                field[FieldKey.required.key] = true;
//                numberFieldView = NumberFieldView(field: field);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField.placeholder) == "Number Field *"
//            }
//            
//            it("field is not valid if value is below min") {
//                field[FieldKey.min.key] = 2;
//                field[FieldKey.max.key] = 8;
//                numberFieldView = NumberFieldView(field: field, value: "1");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                expect(numberFieldView.isValid()) == false;
//            }
//            
//            it("field is not valid if value is above max") {
//                field[FieldKey.min.key] = 2;
//                field[FieldKey.max.key] = 8;
//                numberFieldView = NumberFieldView(field: field, value: "9");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                expect(numberFieldView.isValid()) == false;
//            }
//            
//            it("field is valid if value is between min and max") {
//                field[FieldKey.min.key] = 2;
//                field[FieldKey.max.key] = 8;
//                numberFieldView = NumberFieldView(field: field, value: "5");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                expect(numberFieldView.isValid()) == true;
//            }
//            
//            it("field is valid if value is above min") {
//                field[FieldKey.min.key] = 2;
//                numberFieldView = NumberFieldView(field: field, value: "5");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                expect(numberFieldView.isValid()) == true;
//            }
//            
//            it("field is valid if value is below max") {
//                field[FieldKey.max.key] = 8;
//                numberFieldView = NumberFieldView(field: field, value: "5");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                expect(numberFieldView.isValid()) == true;
//            }
//            
//            it("verify only numbers are allowed") {
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                expect(numberFieldView.textField(numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "a")) == false;
//                expect(delegate.fieldChangedCalled) == false;
//                expect(numberFieldView.textField.text) == "2";
//            }
//            
//            it("verify if a non number is set it will be invalid") {
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                numberFieldView.textField.text = "a";
//                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
//                expect(delegate.fieldChangedCalled) == false;
//                expect(numberFieldView.textField.text) == "a";
//                expect(numberFieldView.getValue()).to(beNil());
//                expect(numberFieldView.isValid()).to(beFalse());
//            }
//            
//            it("verify setting values on BaseFieldView returns the correct values") {
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate);
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                (numberFieldView as BaseFieldView).setValue("2");
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.getValue()) == 2;
//                expect(((numberFieldView as BaseFieldView).getValue() as! NSNumber)) == 2;
//            }
//            
//            it("verify if number below min is set it will be invalid") {
//                field[FieldKey.min.key] = 2;
//
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                numberFieldView.textField.text = "1";
//                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
//                expect(delegate.fieldChangedCalled) == false;
//                expect(numberFieldView.textField.text) == "1";
//                expect(numberFieldView.getValue()) == 1;
//                expect(numberFieldView.isValid()).to(beFalse());
//            }
//            
//            it("verify if number above max is set it will be invalid") {
//                field[FieldKey.max.key] = 2;
//
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                numberFieldView.textField.text = "3";
//                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
//                expect(delegate.fieldChangedCalled) == false;
//                expect(numberFieldView.textField.text) == "3";
//                expect(numberFieldView.getValue()) == 3;
//                expect(numberFieldView.isValid()).to(beFalse());
//            }
//            
//            it("verify if number too low is set it will be invalid") {
//                field[FieldKey.min.key] = 2;
//                field[FieldKey.max.key] = 8;
//
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                numberFieldView.textField.text = "1";
//                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
//                expect(delegate.fieldChangedCalled) == false;
//                expect(numberFieldView.textField.text) == "1";
//                expect(numberFieldView.getValue()) == 1;
//                expect(numberFieldView.isValid()).to(beFalse());
//            }
//            
//            it("verify if number too high is set it will be invalid") {
//                field[FieldKey.min.key] = 2;
//                field[FieldKey.max.key] = 8;
//                
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                numberFieldView.textField.text = "9";
//                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
//                expect(delegate.fieldChangedCalled) == false;
//                expect(numberFieldView.textField.text) == "9";
//                expect(numberFieldView.getValue()) == 9;
//                expect(numberFieldView.isValid()).to(beFalse());
//            }
//            
//            it("test delegate") {
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//               
//                numberFieldView.textField.text = "5";
//                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
//                expect(delegate.fieldChangedCalled) == true;
//                expect(delegate.newValue as? NSNumber) == 5;
//            }
//            
//            it("allow canceling") {
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                
//                numberFieldView.textField.text = "4";
//                numberFieldView.cancelButtonPressed();
//                expect(delegate.fieldChangedCalled) == false;
//                expect(numberFieldView.textField.text) == "2";
//                expect(numberFieldView.getValue()) == 2;
//            }
//            
//            it("done button should change value") {
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                numberFieldView.textField.text = "4";
//                numberFieldView.doneButtonPressed();
//                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
//                expect(delegate.fieldChangedCalled) == true;
//                expect(numberFieldView.textField.text) == "4";
//                expect(numberFieldView.getValue()) == 4;
//            }
//            
//            it("done button should send nil as new value") {
//                let delegate = MockFieldDelegate()
//                numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
//                numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//                view.addSubview(numberFieldView)
//                numberFieldView.autoPinEdgesToSuperviewEdges();
//                numberFieldView.textField.text = "";
//                numberFieldView.doneButtonPressed();
//                numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
//                expect(delegate.fieldChangedCalled) == true;
//                expect(numberFieldView.textField.text) == "";
//                expect(numberFieldView.getValue()).to(beNil());
//            }
//        }
//    }
//}
