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

class NumberFieldViewTests: XCTestCase {
    
    var numberFieldView: NumberFieldView!
    var field: [String: Any]!
                
    var view: UIView!
    var controller: UIViewController!
    var window: UIWindow!;
    
    @MainActor
    override func setUp() {
        controller = UIViewController();
        view = UIView(forAutoLayout: ());
        view.autoSetDimension(.width, toSize: 300);
        view.backgroundColor = .white;

        controller.view.addSubview(view);
        
        window = TestHelpers.getKeyWindowVisible();

        controller = UIViewController();
        view = UIView(forAutoLayout: ());
        view.autoSetDimension(.width, toSize: 300);
        view.backgroundColor = .white;
        
        window.rootViewController = controller;
        controller.view.addSubview(view);
    
        field = [
            "title": "Number Field",
            "name": "field8",
            "id": 8
        ];
//                Nimble_Snapshots.setNimbleTolerance(0.0);
//                Nimble_Snapshots.recordAllSnapshots()
    }
    
    @MainActor
    override func tearDown() {
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
    }
    
    @MainActor
    func testEditModeReferenceImage() {
        field[FieldKey.min.key] = 2;
        field[FieldKey.required.key] = true;
        numberFieldView = NumberFieldView(field: field, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.textField.placeholder) == "Number Field *"
        expect(self.numberFieldView.textField.leadingAssistiveLabel.text) == "Must be greater than 2 "
        expect(self.numberFieldView.titleLabel.text) == "Must be greater than 2 "
        
//                expect(view).to(haveValidSnapshot());
    }
    @MainActor
    func testNoInitialValue() {
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.fieldValue.text).to(beNil());
        expect(self.numberFieldView.textField.text) == "";
        expect(self.numberFieldView.fieldNameLabel.text) == "Number Field"
    }
    
    @MainActor
    func testInitialValueSet() {
        numberFieldView = NumberFieldView(field: field, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.fieldNameLabel.text) == "Number Field"
    }
    
    @MainActor
    func testSetValueViaInput() {
        let delegate = MockFieldDelegate();
        
        numberFieldView = NumberFieldView(field: field, delegate: delegate);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField.text) == "";
        
        tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
        tester().enterText("2", intoViewWithAccessibilityLabel: field[FieldKey.name.key] as? String);
        tester().tapView(withAccessibilityLabel: "Done");
        
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.fieldNameLabel.text) == "Number Field"
        
        expect(delegate.fieldChangedCalled).to(beTrue());
    }
    
    @MainActor
    func testInitialValueSetWithMin() {
        field[FieldKey.min.key] = 2;
        numberFieldView = NumberFieldView(field: field, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.textField.placeholder) == "Number Field"
        expect(self.numberFieldView.textField.leadingAssistiveLabel.text) == "Must be greater than 2 "
        expect(self.numberFieldView.titleLabel.text) == "Must be greater than 2 "
    }
    
    @MainActor
    func testInitialValueSetWithMax() {
        field[FieldKey.max.key] = 8;
        numberFieldView = NumberFieldView(field: field, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.textField.placeholder) == "Number Field"
        expect(self.numberFieldView.textField.leadingAssistiveLabel.text) == "Must be less than 8"
        expect(self.numberFieldView.titleLabel.text) == "Must be less than 8"
    }
    
    @MainActor
    func testInitialValueSetWithMinAndMax() {
        field[FieldKey.min.key] = 2;
        field[FieldKey.max.key] = 8;
        numberFieldView = NumberFieldView(field: field, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.textField.placeholder) == "Number Field"
        expect(self.numberFieldView.textField.leadingAssistiveLabel.text) == "Must be between 2 and 8"
        expect(self.numberFieldView.titleLabel.text) == "Must be between 2 and 8"
    }
    
    @MainActor
    func testSetValueLater() {
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField.text) == "";
        
        numberFieldView.setValue("2")
        
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.fieldNameLabel.text) == "Number Field"
    }
    
    @MainActor
    func testSetValidFalse() {
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        numberFieldView.setValid(false);
        
        expect(self.numberFieldView.textField.text) == "";
        expect(self.numberFieldView.textField.placeholder) == "Number Field"
        expect(self.numberFieldView.textField.leadingAssistiveLabel.text) == "Must be a number"
    }
    
    @MainActor
    func testSetValidTrueAfterBeingInvalid() {
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField.text) == "";
        expect(self.numberFieldView.textField.placeholder) == "Number Field"
        expect(self.numberFieldView.textField.leadingAssistiveLabel.text) == " ";
        numberFieldView.setValid(false);
        expect(self.numberFieldView.textField.leadingAssistiveLabel.text) == "Must be a number"
        numberFieldView.setValid(true);
        expect(self.numberFieldView.textField.leadingAssistiveLabel.text).to(beNil());
    }
    
    @MainActor
    func testRequiredFieldIsInvalidIfEmpty() {
        field[FieldKey.required.key] = true;
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.numberFieldView.isEmpty()) == true;
        expect(self.numberFieldView.isValid(enforceRequired: true)) == false;
        
        expect(self.numberFieldView.textField.text) == "";
        expect(self.numberFieldView.textField.placeholder) == "Number Field *"
    }
    
    @MainActor
    func testRequiredFieldIsInvalidIfTextIsNil() {
        field[FieldKey.required.key] = true;
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        numberFieldView.textField.text = nil;
        expect(self.numberFieldView.isEmpty()) == true;
        expect(self.numberFieldView.isValid(enforceRequired: true)) == false;
        expect(self.numberFieldView.textField.placeholder) == "Number Field *"
    }
    
    @MainActor
    func testFieldIsInvalidIfTextIsALetter() {
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        numberFieldView.textField.text = "a";
        expect(self.numberFieldView.isEmpty()) == false;
        expect(self.numberFieldView.isValid(enforceRequired: true)) == false;
        expect(self.numberFieldView.textField.placeholder) == "Number Field"
    }
    
    @MainActor
    func testFieldShouldAllowChangingTextToAValueNumber() {
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        numberFieldView.textField.text = "1";
        expect(self.numberFieldView.textField(self.numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "2")) == true;
        expect(self.numberFieldView.isEmpty()) == false;
    }
    
    @MainActor
    func testFieldShouldAllowChangingTextToABlank() {
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        numberFieldView.textField.text = "1";
        expect(self.numberFieldView.textField(self.numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "")) == true;
    }
    
    @MainActor
    func testRequiredFieldIsValidIfNotEmpty() {
        field[FieldKey.required.key] = true;
        numberFieldView = NumberFieldView(field: field, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.numberFieldView.isEmpty()) == false;
        expect(self.numberFieldView.isValid(enforceRequired: true)) == true;
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.textField.placeholder) == "Number Field *"
    }
    
    @MainActor
    func testRequiredFieldHasTitleWhichIndicatesRequired() {
        field[FieldKey.required.key] = true;
        numberFieldView = NumberFieldView(field: field);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField.placeholder) == "Number Field *"
    }
    
    @MainActor
    func testFieldIsNotValidIfValueIsBelowMin() {
        field[FieldKey.min.key] = 2;
        field[FieldKey.max.key] = 8;
        numberFieldView = NumberFieldView(field: field, value: "1");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.numberFieldView.isValid()) == false;
    }
    
    @MainActor
    func testFieldIsNotValidIfValueIsAboveMax() {
        field[FieldKey.min.key] = 2;
        field[FieldKey.max.key] = 8;
        numberFieldView = NumberFieldView(field: field, value: "9");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.numberFieldView.isValid()) == false;
    }
    
    @MainActor
    func testFieldIsValidIfValueIsBetweenMinAndMax() {
        field[FieldKey.min.key] = 2;
        field[FieldKey.max.key] = 8;
        numberFieldView = NumberFieldView(field: field, value: "5");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.numberFieldView.isValid()) == true;
    }
    
    @MainActor
    func testFieldIsValidIfValueIsAboveMin() {
        field[FieldKey.min.key] = 2;
        numberFieldView = NumberFieldView(field: field, value: "5");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.numberFieldView.isValid()) == true;
    }
    
    @MainActor
    func testFieldIsValidIfValueIsBelowMax() {
        field[FieldKey.max.key] = 8;
        numberFieldView = NumberFieldView(field: field, value: "5");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.numberFieldView.isValid()) == true;
    }
    
    @MainActor
    func testVerifyOnlyNumbersAreAllowed() {
        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.numberFieldView.textField(self.numberFieldView.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: "a")) == false;
        expect(delegate.fieldChangedCalled) == false;
        expect(self.numberFieldView.textField.text) == "2";
    }
    
    @MainActor
    func testVerifyIfANonNumberIsSetItWillBeInvalid() {
        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        numberFieldView.textField.text = "a";
        numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
        expect(delegate.fieldChangedCalled) == false;
        expect(self.numberFieldView.textField.text) == "a";
        expect(self.numberFieldView.getValue()).to(beNil());
        expect(self.numberFieldView.isValid()).to(beFalse());
    }
    
    @MainActor
    func testVerifySettingValuesOnBaseFieldViewReturnsTheCorrectValues() {
        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate);
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        (numberFieldView as BaseFieldView).setValue("2");
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.getValue()) == 2;
        expect(((self.numberFieldView as BaseFieldView).getValue() as! NSNumber)) == 2;
    }
    
    @MainActor
    func testVerifyIfNumberBelowMinIsSetItWillBeInvalid() {
        field[FieldKey.min.key] = 2;

        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        numberFieldView.textField.text = "1";
        numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
        expect(delegate.fieldChangedCalled) == false;
        expect(self.numberFieldView.textField.text) == "1";
        expect(self.numberFieldView.getValue()) == 1;
        expect(self.numberFieldView.isValid()).to(beFalse());
    }
    
    @MainActor
    func testVerifyIfNumberAboveMaxIsSetItWillBeInvalid() {
        field[FieldKey.max.key] = 2;

        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        numberFieldView.textField.text = "3";
        numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
        expect(delegate.fieldChangedCalled) == false;
        expect(self.numberFieldView.textField.text) == "3";
        expect(self.numberFieldView.getValue()) == 3;
        expect(self.numberFieldView.isValid()).to(beFalse());
    }
    
    @MainActor
    func testVerifyIfNumberTooLowIsSetItWillBeInvalid() {
        field[FieldKey.min.key] = 2;
        field[FieldKey.max.key] = 8;

        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        numberFieldView.textField.text = "1";
        numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
        expect(delegate.fieldChangedCalled) == false;
        expect(self.numberFieldView.textField.text) == "1";
        expect(self.numberFieldView.getValue()) == 1;
        expect(self.numberFieldView.isValid()).to(beFalse());
    }
    
    @MainActor
    func testVerifyIfNumberTooHighIsSetItWillBeInvalid() {
        field[FieldKey.min.key] = 2;
        field[FieldKey.max.key] = 8;
        
        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        numberFieldView.textField.text = "9";
        numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
        expect(delegate.fieldChangedCalled) == false;
        expect(self.numberFieldView.textField.text) == "9";
        expect(self.numberFieldView.getValue()) == 9;
        expect(self.numberFieldView.isValid()).to(beFalse());
    }
    
    @MainActor
    func testDelegate() {
        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
       
        numberFieldView.textField.text = "5";
        numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
        expect(delegate.fieldChangedCalled) == true;
        expect(delegate.newValue as? NSNumber) == 5;
    }
    
    @MainActor
    func testAllowCancelling() {
        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        
        numberFieldView.textField.text = "4";
        numberFieldView.cancelButtonPressed();
        expect(delegate.fieldChangedCalled) == false;
        expect(self.numberFieldView.textField.text) == "2";
        expect(self.numberFieldView.getValue()) == 2;
    }
    
    @MainActor
    func testDoneButtonShouldChangeValue() {
        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        numberFieldView.textField.text = "4";
        numberFieldView.doneButtonPressed();
        numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
        expect(delegate.fieldChangedCalled) == true;
        expect(self.numberFieldView.textField.text) == "4";
        expect(self.numberFieldView.getValue()) == 4;
    }
    
    @MainActor
    func testDoneButtonShouldSendNilAsNewValue() {
        let delegate = MockFieldDelegate()
        numberFieldView = NumberFieldView(field: field, delegate: delegate, value: "2");
        numberFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(numberFieldView)
        numberFieldView.autoPinEdgesToSuperviewEdges();
        numberFieldView.textField.text = "";
        numberFieldView.doneButtonPressed();
        numberFieldView.textFieldDidEndEditing(numberFieldView.textField);
        expect(delegate.fieldChangedCalled) == true;
        expect(self.numberFieldView.textField.text) == "";
        expect(self.numberFieldView.getValue()).to(beNil());
    }
}
