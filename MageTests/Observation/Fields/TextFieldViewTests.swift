//
//  TextFieldViewTests.swift
//  MAGE
//
//  Created by Daniel Barela on 5/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class TextFieldViewTests: KIFSpec {
    
    override func spec() {
                
        describe("TextFieldView Single Line") {
            
            var textFieldView: TextFieldView!
            var field: [String: Any]!
            
            var view: UIView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            beforeEach {
                window = TestHelpers.getKeyWindowVisible();
                
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .white;
                
                window.rootViewController = controller;
                controller.view.addSubview(view);

                field = [
                    FieldKey.title.key: "Field Title",
                    FieldKey.name.key: "field8",
                    FieldKey.id.key: 8
                ];
                Nimble_Snapshots.setNimbleTolerance(0.0);
//                Nimble_Snapshots.recordAllSnapshots()
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
            }
            
            it("non edit mode reference image") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field, editMode: false, value: "Hello");
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.fieldValue.text) == "Hello";
                expect(textFieldView.fieldNameLabel.text) == "Field Title"
                
                expect(view).to(haveValidSnapshot());
            }
            
            it("edit mode reference image") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field, editMode: true, value: "Hello");
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.textField.text) == "Hello";
                expect(textFieldView.textField.placeholder) == "Field Title *"
                
                expect(view).to(haveValidSnapshot());
            }
            
            it("set valid false") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValid(false);
                
                expect(textFieldView.textField.placeholder) == "Field Title *"
                expect(textFieldView.textField.leadingAssistiveLabel.text) == "Field Title is required"
                
                expect(view).to(haveValidSnapshot());
            }
            
            it("email field") {
                textFieldView = TextFieldView(field: field, keyboardType: .emailAddress);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                expect(textFieldView.textField.keyboardType) == .emailAddress;
                
                expect(textFieldView.textField.placeholder) == "Field Title"
            }
            
            it("no initial value") {
                textFieldView = TextFieldView(field: field);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
 
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
                
                expect(textFieldView.textField.placeholder) == "Field Title"
                expect(textFieldView.textField.text) == ""
            }
            
            it("initial value set") {
                textFieldView = TextFieldView(field: field, value: "Hello");
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.textField.placeholder) == "Field Title"
                expect(textFieldView.textField.text) == "Hello";
            }
            
            it("set value later") {
                textFieldView = TextFieldView(field: field);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValue("Hi")
                
                expect(textFieldView.textField.placeholder) == "Field Title"
                expect(textFieldView.textField.text) == "Hi";
            }
            
            it("set value via input") {
                let delegate = MockFieldDelegate();

                textFieldView = TextFieldView(field: field, delegate: delegate);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().enterText("new text", intoViewWithAccessibilityLabel: field["name"] as? String);
                tester().tapView(withAccessibilityLabel: "Done");
                
                expect(delegate.fieldChangedCalled).to(beTrue());
                
                expect(textFieldView.textField.placeholder) == "Field Title"
                expect(textFieldView.textField.text) == "new text";
            }
            
            it("set valid true after being invalid") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValid(false);
                expect(textFieldView.textField.placeholder) == "Field Title *"
                expect(textFieldView.textField.leadingAssistiveLabel.text) == "Field Title is required"
                textFieldView.setValid(true);
                expect(textFieldView.textField.placeholder) == "Field Title *"
                expect(textFieldView.textField.leadingAssistiveLabel.text) == " ";
            }
            
            it("required field is invalid if empty") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(textFieldView.isEmpty()) == true;
                expect(textFieldView.isValid(enforceRequired: true)) == false;
            }
            
            it("required field is valid if not empty") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field, value: "valid");
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(textFieldView.isEmpty()) == false;
                expect(textFieldView.isValid(enforceRequired: true)) == true;
            }
            
            it("required field has title which indicates required") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.textField.placeholder) == "Field Title *"
            }
            
            it("test delegate") {
                let delegate = MockFieldDelegate();
                textFieldView = TextFieldView(field: field, delegate: delegate);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.textField.text = "new value";
                textFieldView.textFieldDidEndEditing(textFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? String) == "new value";
            }
            
            it("done button should send nil as new value") {
                let delegate = MockFieldDelegate();

                textFieldView = TextFieldView(field: field, delegate: delegate, value: "old value");
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.textField.text = nil;
                textFieldView.doneButtonPressed();
                textFieldView.textFieldDidEndEditing(textFieldView.textField);
                expect(delegate.fieldChangedCalled).to(beTrue());
                expect(delegate.newValue).to(beNil());
                expect(textFieldView.textField.text).to(equal(""));
                expect(textFieldView.value as? String).to(beNil());
            }
            
            it("done button should change text") {
                textFieldView = TextFieldView(field: field, value: "old value");
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.textField.text = "new value";
                textFieldView.doneButtonPressed();
                textFieldView.textFieldDidEndEditing(textFieldView.textField);
                expect(textFieldView.textField.text) == "new value";
                expect(textFieldView.value as? String) == "new value";
            }
            
            it("cancel button should not change text") {
                textFieldView = TextFieldView(field: field, value: "old value");
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.textField.text = "new value";
                textFieldView.cancelButtonPressed();
                expect(textFieldView.textField.text) == "old value";
                expect(textFieldView.value as? String) == "old value";
            }
        }
        
        describe("TextFieldView Multi Line") {
            
            var textFieldView: TextFieldView!
            var field: [String: Any]!
                        
            var view: UIView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            beforeEach {
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .white;
                
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                
                controller.view.addSubview(view);

                field = ["title": "Multi Line Field Title",
                         "name": "field8",
                         "id": 8
                ];
                Nimble_Snapshots.setNimbleTolerance(0.0);
//                Nimble_Snapshots.recordAllSnapshots()
            }
            
            it("non edit mode reference image") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field, editMode: false, value: "Hi\nHello", multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.fieldValue.text) == "Hi\nHello";
                expect(textFieldView.fieldNameLabel.text) == "Multi Line Field Title"
                
                expect(view).to(haveValidSnapshot());
            }
            
            it("edit mode reference image") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field, editMode: true, value: "Hi\nHello", multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges()
                
                expect(textFieldView.multilineTextField.textView.text) == "Hi\nHello";
                expect(textFieldView.multilineTextField.placeholder) == "Multi Line Field Title *"
                
                expect(view).to(haveValidSnapshot());
            }
            
            it("set valid false") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field, multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValid(false);
                expect(textFieldView.multilineTextField.placeholder) == "Multi Line Field Title *"
                expect(textFieldView.multilineTextField.leadingAssistiveLabel.text) == "Multi Line Field Title is required"
                
                expect(view).to(haveValidSnapshot());
            }
            
            it("non edit mode") {
                textFieldView = TextFieldView(field: field, editMode: false, value: "Hi\nHello", multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.fieldValue.text) == "Hi\nHello";
                expect(textFieldView.fieldNameLabel.text) == "Multi Line Field Title"
            }
            
            it("no initial value") {
                textFieldView = TextFieldView(field: field, multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.multilineTextField.textView.text) == "";
                expect(textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
            }
            
            it("initial value set") {
                textFieldView = TextFieldView(field: field, value: "Hello", multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.multilineTextField.textView.text) == "Hello";
                expect(textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
            }
            
            it("set value later") {
                textFieldView = TextFieldView(field: field, multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.multilineTextField.textView.text) == "";
                
                textFieldView.setValue("Hi")
                
                expect(textFieldView.multilineTextField.textView.text) == "Hi";
                expect(textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
            }
            
            it("set multi line value later") {
                textFieldView = TextFieldView(field: field, multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.multilineTextField.textView.text) == "";
                
                textFieldView.setValue("Hi\nHello")
                
                expect(textFieldView.multilineTextField.textView.text) == "Hi\nHello";
                expect(textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
            }
            
            it("set value via input") {
                let delegate = MockFieldDelegate();
                
                textFieldView = TextFieldView(field: field, delegate: delegate, multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                expect(textFieldView.multilineTextField.textView.text) == "";
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().enterText("new\ntext", intoViewWithAccessibilityLabel: field["name"] as? String);
                tester().tapView(withAccessibilityLabel: "Done");
                
                expect(delegate.fieldChangedCalled).to(beTrue());
                
                expect(textFieldView.multilineTextField.textView.text) == "new\ntext";
                expect(textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
            }
            
            it("set valid true after being invalid") {
                textFieldView = TextFieldView(field: field, multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.multilineTextField.textView.text) == "";
                expect(textFieldView.multilineTextField.placeholder) == "Multi Line Field Title"
                expect(textFieldView.multilineTextField.leadingAssistiveLabel.text) == " ";
                textFieldView.setValid(false);
                expect(textFieldView.multilineTextField.leadingAssistiveLabel.text) == "Multi Line Field Title is required"
                textFieldView.setValid(true);
                expect(textFieldView.multilineTextField.leadingAssistiveLabel.text) == " ";
            }
            
            it("required field is invalid if empty") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field, multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(textFieldView.isEmpty()) == true;
                expect(textFieldView.isValid(enforceRequired: true)) == false;
            }
            
            it("required field is valid if not empty") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field, value: "valid", multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(textFieldView.isEmpty()) == false;
                expect(textFieldView.isValid(enforceRequired: true)) == true;
            }
            
            it("required field has title which indicates required") {
                field[FieldKey.required.key] = true;
                textFieldView = TextFieldView(field: field, multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(textFieldView.multilineTextField.placeholder) == "Multi Line Field Title *"
            }
            
            it("test delegate") {
                let delegate = MockFieldDelegate();
                textFieldView = TextFieldView(field: field, delegate: delegate, multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                textFieldView.multilineTextField.textView.text = "this is a new value";
                textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? String) == "this is a new value";
            }
            
            it("done button should send nil as new value") {
                let delegate = MockFieldDelegate();
                
                textFieldView = TextFieldView(field: field, delegate: delegate, value: "old value");
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.multilineTextField.textView.text = nil;
                textFieldView.doneButtonPressed();
                textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView);
                expect(delegate.fieldChangedCalled).to(beTrue());
                expect(delegate.newValue).to(beNil());
                expect(textFieldView.multilineTextField.textView.text).to(equal(""));
                expect(textFieldView.value as? String).to(beNil());
            }
            
            it("done button should change text") {
                textFieldView = TextFieldView(field: field, value: "old value", multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.multilineTextField.textView.text = "new value";
                textFieldView.doneButtonPressed();
                textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView);
                expect(textFieldView.multilineTextField.textView.text) == "new value";
                expect(textFieldView.value as? String) == "new value";
            }
            
            it("cancel button should not change text") {
                textFieldView = TextFieldView(field: field, value: "old value", multiline: true);
                textFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.multilineTextField.textView.text = "new value";
                textFieldView.cancelButtonPressed();
                expect(textFieldView.multilineTextField.textView.text) == "old value";
                expect(textFieldView.value as? String) == "old value";
            }
        }
    }
}
