////
////  TextFieldViewTests.swift
////  MAGE
////
////  Created by Daniel Barela on 5/8/20.
////  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
////
//
//import Foundation
//import Quick
//import Nimble
//
//@testable import MAGE
//
//class TextFieldViewTests: XCTestCase {
//
//    
//    var textFieldView: TextFieldView!
//    var field: [String: Any]!
//    
//    var view: UIView!
//    var controller: UIViewController!
//    var window: UIWindow!;
//    
//    @MainActor
//    override func setUp() {
//        window = TestHelpers.getKeyWindowVisible();
//        
//        controller = UIViewController();
//        view = UIView(forAutoLayout: ());
//        view.autoSetDimension(.width, toSize: 300);
//        view.backgroundColor = .white;
//        
//        window.rootViewController = controller;
//        controller.view.addSubview(view);
//
//        field = [
//            FieldKey.title.key: "Field Title",
//            FieldKey.name.key: "field8",
//            FieldKey.id.key: 8
//        ];
//    }
//    
//    @MainActor
//    override func tearDown() {
//        controller.dismiss(animated: false, completion: nil);
//        window.rootViewController = nil;
//        controller = nil;
//    }
//    
//    @MainActor
//    func testEditModeReferenceImag() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field, editMode: true, value: "Hello");
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.textField.text) == "Hello";
//        expect(self.textFieldView.textField.placeholder) == "Field Title *"
//        
////                expect(view).to(haveValidSnapshot());
//    }
//    
//    @MainActor
//    func testSetValidFalse() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.setValid(false);
//        
//        expect(self.textFieldView.textField.placeholder) == "Field Title *"
//        expect(self.textFieldView.textField.leadingAssistiveLabel.text) == "Field Title is required"
//        
////                expect(view).to(haveValidSnapshot());
//    }
//    
//    @MainActor
//    func testEmailField() {
//        textFieldView = TextFieldView(field: field, keyboardType: .emailAddress);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        expect(self.textFieldView.textField.keyboardType) == .emailAddress;
//        
//        expect(self.textFieldView.textField.placeholder) == "Field Title"
//    }
//    
//    @MainActor
//    func testNoInitialValue() {
//        textFieldView = TextFieldView(field: field);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
//        
//        expect(self.textFieldView.textField.placeholder) == "Field Title"
//        expect(self.textFieldView.textField.text) == ""
//    }
//    
//    @MainActor
//    func testInitialValueSet() {
//        textFieldView = TextFieldView(field: field, value: "Hello");
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.textField.placeholder) == "Field Title"
//        expect(self.textFieldView.textField.text) == "Hello";
//    }
//    
//    @MainActor
//    func testSetValueLater() {
//        textFieldView = TextFieldView(field: field);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.setValue("Hi")
//        
//        expect(self.textFieldView.textField.placeholder) == "Field Title"
//        expect(self.textFieldView.textField.text) == "Hi";
//    }
//    
//    @MainActor
//    func testSetValueViaInput() {
//        let delegate = MockFieldDelegate();
//
//        textFieldView = TextFieldView(field: field, delegate: delegate);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        tester().waitForView(withAccessibilityLabel: field["name"] as? String);
//        tester().enterText("new text", intoViewWithAccessibilityLabel: field["name"] as? String);
//        tester().tapView(withAccessibilityLabel: "Done");
//        
//        expect(delegate.fieldChangedCalled).to(beTrue());
//        
//        expect(self.textFieldView.textField.placeholder) == "Field Title"
//        expect(self.textFieldView.textField.text) == "new text";
//    }
//    
//    @MainActor
//    func testSetValidTrueAfterBeingInvalid() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.setValid(false);
//        expect(self.textFieldView.textField.placeholder) == "Field Title *"
//        expect(self.textFieldView.textField.leadingAssistiveLabel.text) == "Field Title is required"
//        textFieldView.setValid(true);
//        expect(self.textFieldView.textField.placeholder) == "Field Title *"
//        expect(self.textFieldView.textField.leadingAssistiveLabel.text) == " ";
//    }
//    
//    @MainActor
//    func testRequiredFieldIsInvalidIfEmpty() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        expect(self.textFieldView.isEmpty()) == true;
//        expect(self.textFieldView.isValid(enforceRequired: true)) == false;
//    }
//    
//    @MainActor
//    func testRequiredFieldIsValidIfNotEmpty() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field, value: "valid");
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        expect(self.textFieldView.isEmpty()) == false;
//        expect(self.textFieldView.isValid(enforceRequired: true)) == true;
//    }
//    
//    @MainActor
//    func testRequiredFieldHasTitleWhichIndicatesRequired() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.textField.placeholder) == "Field Title *"
//    }
//    
//    @MainActor
//    func testDelegate() {
//        let delegate = MockFieldDelegate();
//        textFieldView = TextFieldView(field: field, delegate: delegate);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.textField.text = "new value";
//        textFieldView.textFieldDidEndEditing(textFieldView.textField);
//        expect(delegate.fieldChangedCalled) == true;
//        expect(delegate.newValue as? String) == "new value";
//    }
//    
//    @MainActor
//    func testDoneButtonShouldSendNilAsNewValue() {
//        let delegate = MockFieldDelegate();
//
//        textFieldView = TextFieldView(field: field, delegate: delegate, value: "old value");
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.textField.text = nil;
//        textFieldView.doneButtonPressed();
//        textFieldView.textFieldDidEndEditing(textFieldView.textField);
//        expect(delegate.fieldChangedCalled).to(beTrue());
//        expect(delegate.newValue).to(beNil());
//        expect(self.textFieldView.textField.text).to(equal(""));
//        expect(self.textFieldView.value as? String).to(beNil());
//    }
//    
//    @MainActor
//    func testDoneButtonShouldChangeText() {
//        textFieldView = TextFieldView(field: field, value: "old value");
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.textField.text = "new value";
//        textFieldView.doneButtonPressed();
//        textFieldView.textFieldDidEndEditing(textFieldView.textField);
//        expect(self.textFieldView.textField.text) == "new value";
//        expect(self.textFieldView.value as? String) == "new value";
//    }
//    
//    @MainActor
//    func testCancelButtonShouldNotChangeText() {
//        textFieldView = TextFieldView(field: field, value: "old value");
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.textField.text = "new value";
//        textFieldView.cancelButtonPressed();
//        expect(self.textFieldView.textField.text) == "old value";
//        expect(self.textFieldView.value as? String) == "old value";
//    }
//}
//
//class TextFieldMultiLineViewTests: XCTestCase {
//
//    
//    var textFieldView: TextFieldView!
//    var field: [String: Any]!
//    
//    var view: UIView!
//    var controller: UIViewController!
//    var window: UIWindow!;
//    
//    @MainActor
//    override func setUp() {
//        window = TestHelpers.getKeyWindowVisible();
//        
//        controller = UIViewController();
//        view = UIView(forAutoLayout: ());
//        view.autoSetDimension(.width, toSize: 300);
//        view.backgroundColor = .white;
//        
//        window.rootViewController = controller;
//        controller.view.addSubview(view);
//
//        field = [
//            FieldKey.title.key: "Multi Line Field Title",
//            FieldKey.name.key: "field8",
//            FieldKey.id.key: 8
//        ];
//    }
//    
//    @MainActor
//    override func tearDown() {
//        controller.dismiss(animated: false, completion: nil);
//        window.rootViewController = nil;
//        controller = nil;
//    }
//    
//    @MainActor
//    func testEditModeReferenceImage() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field, editMode: true, value: "Hi\nHello", multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges()
//        
//        expect(self.textFieldView.multilineTextField.textView.text) == "Hi\nHello";
//        expect(self.textFieldView.multilineTextField.placeholder) == "Multi Line Field Title *"
//        
////                expect(view).to(haveValidSnapshot());
//    }
//    
//    @MainActor
//    func testSetValidFalse() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field, multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.setValid(false);
//        expect(self.textFieldView.multilineTextField.placeholder) == "Multi Line Field Title *"
//        expect(self.textFieldView.multilineTextField.leadingAssistiveLabel.text) == "Multi Line Field Title is required"
//        
////                expect(view).to(haveValidSnapshot());
//    }
//    
//    @MainActor
//    func testNonEditMode() {
//        textFieldView = TextFieldView(field: field, editMode: false, value: "Hi\nHello", multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.fieldValue.text) == "Hi\nHello";
//        expect(self.textFieldView.fieldNameLabel.text) == "Multi Line Field Title"
//    }
//    
//    @MainActor
//    func testNoInitialValue() {
//        textFieldView = TextFieldView(field: field, multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.multilineTextField.textView.text) == "";
//        expect(self.textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
//    }
//    
//    @MainActor
//    func testInitialValueSet() {
//        textFieldView = TextFieldView(field: field, value: "Hello", multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.multilineTextField.textView.text) == "Hello";
//        expect(self.textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
//    }
//    
//    @MainActor
//    func testSetValueLater() {
//        textFieldView = TextFieldView(field: field, multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.multilineTextField.textView.text) == "";
//        
//        textFieldView.setValue("Hi")
//        
//        expect(self.textFieldView.multilineTextField.textView.text) == "Hi";
//        expect(self.textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
//    }
//    
//    @MainActor
//    func testSetMultiLineValueLater() {
//        textFieldView = TextFieldView(field: field, multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.multilineTextField.textView.text) == "";
//        
//        textFieldView.setValue("Hi\nHello")
//        
//        expect(self.textFieldView.multilineTextField.textView.text) == "Hi\nHello";
//        expect(self.textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
//    }
//    
//    @MainActor
//    func testSetValueViaInput() {
//        let delegate = MockFieldDelegate();
//        
//        textFieldView = TextFieldView(field: field, delegate: delegate, multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        expect(self.textFieldView.multilineTextField.textView.text) == "";
//        
//        tester().waitForView(withAccessibilityLabel: field["name"] as? String);
//        tester().enterText("new\ntext", intoViewWithAccessibilityLabel: field["name"] as? String);
//        tester().tapView(withAccessibilityLabel: "Done");
//        
//        expect(delegate.fieldChangedCalled).to(beTrue());
//        
//        expect(self.textFieldView.multilineTextField.textView.text) == "new\ntext";
//        expect(self.textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
//    }
//    
//    @MainActor
//    func testSetValidTrueAfterBeingInvalid() {
//        textFieldView = TextFieldView(field: field, multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.multilineTextField.textView.text) == "";
//        expect(self.textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
//        expect(self.textFieldView.multilineTextField.leadingAssistiveLabel.text) == " ";
//        textFieldView.setValid(false);
//        expect(self.textFieldView.multilineTextField.leadingAssistiveLabel.text) == "Multi Line Field Title is required"
//        textFieldView.setValid(true);
//        expect(self.textFieldView.multilineTextField.leadingAssistiveLabel.text) == " ";
//    }
//    
//    @MainActor
//    func testRequiredFieldIsInvalidIfEmpty() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field, multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        expect(self.textFieldView.isEmpty()) == true;
//        expect(self.textFieldView.isValid(enforceRequired: true)) == false;
//    }
//    
//    @MainActor
//    func testRequiredFieldIsValidIfNotEmpty() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field, value: "valid", multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        expect(self.textFieldView.isEmpty()) == false;
//        expect(self.textFieldView.isValid(enforceRequired: true)) == true;
//    }
//    
//    @MainActor
//    func testRequiredFieldHasTitleWhichIndicatesRequired() {
//        field[FieldKey.required.key] = true;
//        textFieldView = TextFieldView(field: field, multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        expect(self.textFieldView.multilineTextField.placeholder) == "Multi Line Field Title *"
//    }
//    
//    @MainActor
//    func testDelegate() {
//        let delegate = MockFieldDelegate();
//        textFieldView = TextFieldView(field: field, delegate: delegate, multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        textFieldView.multilineTextField.textView.text = "this is a new value";
//        textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView);
//        expect(delegate.fieldChangedCalled) == true;
//        expect(delegate.newValue as? String) == "this is a new value";
//    }
//    
//    @MainActor
//    func testDoneButtonShouldSendNilAsNewValue() {
//        let delegate = MockFieldDelegate();
//        
//        textFieldView = TextFieldView(field: field, delegate: delegate, value: "old value");
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.multilineTextField.textView.text = nil;
//        textFieldView.doneButtonPressed();
//        textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView);
//        expect(delegate.fieldChangedCalled).to(beTrue());
//        expect(delegate.newValue).to(beNil());
//        expect(self.textFieldView.multilineTextField.textView.text).to(equal(""));
//        expect(self.textFieldView.value as? String).to(beNil());
//    }
//    
//    @MainActor
//    func testDoneButtonShouldChangeText() {
//        textFieldView = TextFieldView(field: field, value: "old value", multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.multilineTextField.textView.text = "new value";
//        textFieldView.doneButtonPressed();
//        textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView);
//        expect(self.textFieldView.multilineTextField.textView.text) == "new value";
//        expect(self.textFieldView.value as? String) == "new value";
//    }
//    
//    @MainActor
//    func testCancelButtonShouldNotChangeText() {
//        textFieldView = TextFieldView(field: field, value: "old value", multiline: true);
//        textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(textFieldView)
//        textFieldView.autoPinEdgesToSuperviewEdges();
//        
//        textFieldView.multilineTextField.textView.text = "new value";
//        textFieldView.cancelButtonPressed();
//        expect(self.textFieldView.multilineTextField.textView.text) == "old value";
//        expect(self.textFieldView.value as? String) == "old value";
//    }
//}
