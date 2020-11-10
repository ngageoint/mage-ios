//
//  EditTextFieldViewTests.swift
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

class EditTextFieldViewTests: KIFSpec {
    
    override func spec() {
        
        let recordSnapshots = false;
        
        describe("EditTextFieldView Single Line") {
            
            var textFieldView: EditTextFieldView!
            var field: [String: Any]!
            
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
                    "title": "Field Title",
                    "name": "field8",
                    "id": 8
                ];
            }
            
            it("email field") {
                textFieldView = EditTextFieldView(field: field, keyboardType: .emailAddress);
                expect(textFieldView.textField.keyboardType) == .emailAddress;
            }
            
            it("no initial value") {
                textFieldView = EditTextFieldView(field: field);
 
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);

                expect(view) == maybeSnapshot();
            }
            
            it("initial value set") {
                textFieldView = EditTextFieldView(field: field, value: "Hello");
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == maybeSnapshot();
            }
            
            it("set value later") {
                textFieldView = EditTextFieldView(field: field);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValue("Hi")
                expect(view) == maybeSnapshot();
            }
            
            it("set value via input") {
                let delegate = MockFieldDelegate();

                textFieldView = EditTextFieldView(field: field, delegate: delegate);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().enterText("new text", intoViewWithAccessibilityLabel: field["name"] as? String);
                tester().tapView(withAccessibilityLabel: "Done");
                
                expect(delegate.fieldChangedCalled).to(beTrue());
                
                expect(view) == maybeSnapshot();
            }
            
            it("set valid false") {
                textFieldView = EditTextFieldView(field: field);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValid(false);
                expect(view) == maybeSnapshot();
            }
            
            it("set valid true after being invalid") {
                textFieldView = EditTextFieldView(field: field);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValid(false);
                textFieldView.setValid(true);
                expect(view) == maybeSnapshot();
            }
            
            it("required field is invalid if empty") {
                field[FieldKey.required.key] = true;
                textFieldView = EditTextFieldView(field: field);
                
                expect(textFieldView.isEmpty()) == true;
                expect(textFieldView.isValid(enforceRequired: true)) == false;
            }
            
            it("required field is valid if not empty") {
                field[FieldKey.required.key] = true;
                textFieldView = EditTextFieldView(field: field, value: "valid");
                
                expect(textFieldView.isEmpty()) == false;
                expect(textFieldView.isValid(enforceRequired: true)) == true;
            }
            
            it("required field has title which indicates required") {
                field[FieldKey.required.key] = true;
                textFieldView = EditTextFieldView(field: field);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(view) == maybeSnapshot();
            }
            
            it("test delegate") {
                let delegate = MockFieldDelegate();
                textFieldView = EditTextFieldView(field: field, delegate: delegate);
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.textField.text = "new value";
                textFieldView.textFieldDidEndEditing(textFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? String) == "new value";
                expect(view) == maybeSnapshot();
            }
            
            it("done button should send nil as new value") {
                let delegate = MockFieldDelegate();

                textFieldView = EditTextFieldView(field: field, delegate: delegate, value: "old value");
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
                textFieldView = EditTextFieldView(field: field, value: "old value");
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.textField.text = "new value";
                textFieldView.doneButtonPressed();
                textFieldView.textFieldDidEndEditing(textFieldView.textField);
                expect(textFieldView.textField.text) == "new value";
                expect(textFieldView.value as? String) == "new value";
            }
            
            it("cancel button should not change text") {
                textFieldView = EditTextFieldView(field: field, value: "old value");
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.textField.text = "new value";
                textFieldView.cancelButtonPressed();
                expect(textFieldView.textField.text) == "old value";
                expect(textFieldView.value as? String) == "old value";
            }
        }
        
        describe("EditTextFieldView Multi Line") {
            
            var textFieldView: EditTextFieldView!
            var field: [String: Any]!
                        
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

                field = ["title": "Multi Line Field Title",
                         "name": "field8",
                         "id": 8
                ];
            }
            
            it("no initial value") {
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == maybeSnapshot();
            }
            
            it("initial value set") {
                textFieldView = EditTextFieldView(field: field, value: "Hello", multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == maybeSnapshot();
            }
            
            it("set value later") {
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValue("Hi")
                expect(view) == maybeSnapshot();
            }
            
            it("set multi line value later") {
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                view.autoPinEdge(.bottom, to: .bottom, of: textFieldView);
                textFieldView.setValue("Hi\nHello")
                
                expect(view) == maybeSnapshot();
            }
            
            it("set value via input") {
                let delegate = MockFieldDelegate();
                
                textFieldView = EditTextFieldView(field: field, delegate: delegate, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().enterText("new\ntext", intoViewWithAccessibilityLabel: field["name"] as? String);
                tester().tapView(withAccessibilityLabel: "Done");
                
                expect(delegate.fieldChangedCalled).to(beTrue());
                
                expect(view) == maybeSnapshot();
            }
            
            it("set valid false") {
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValid(false);
                expect(view) == maybeSnapshot();
            }
            
            it("set valid true after being invalid") {
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValid(false);
                textFieldView.setValid(true);
                expect(view) == maybeSnapshot();
            }
            
            it("required field is invalid if empty") {
                field[FieldKey.required.key] = true;
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                expect(textFieldView.isEmpty()) == true;
                expect(textFieldView.isValid(enforceRequired: true)) == false;
            }
            
            it("required field is valid if not empty") {
                field[FieldKey.required.key] = true;
                textFieldView = EditTextFieldView(field: field, value: "valid", multiline: true);
                
                expect(textFieldView.isEmpty()) == false;
                expect(textFieldView.isValid(enforceRequired: true)) == true;
            }
            
            it("required field has title which indicates required") {
                field[FieldKey.required.key] = true;
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(view) == maybeSnapshot();
            }
            
            it("test delegate") {
                let delegate = MockFieldDelegate();
                textFieldView = EditTextFieldView(field: field, delegate: delegate, multiline: true);
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                textFieldView.multilineTextField.text = "this is a new value";
                textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView!);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? String) == "this is a new value";
                expect(view) == maybeSnapshot();
            }
            
            it("done button should send nil as new value") {
                let delegate = MockFieldDelegate();
                
                textFieldView = EditTextFieldView(field: field, delegate: delegate, value: "old value");
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.multilineTextField.text = nil;
                textFieldView.doneButtonPressed();
                textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView!);
                expect(delegate.fieldChangedCalled).to(beTrue());
                expect(delegate.newValue).to(beNil());
                expect(textFieldView.multilineTextField.text).to(equal(""));
                expect(textFieldView.value as? String).to(beNil());
            }
            
            it("done button should change text") {
                textFieldView = EditTextFieldView(field: field, value: "old value", multiline: true);
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.multilineTextField.text = "new value";
                textFieldView.doneButtonPressed();
                textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView!);
                expect(textFieldView.multilineTextField.text) == "new value";
                expect(textFieldView.value as? String) == "new value";
            }
            
            it("cancel button should not change text") {
                textFieldView = EditTextFieldView(field: field, value: "old value", multiline: true);
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.multilineTextField.text = "new value";
                textFieldView.cancelButtonPressed();
                expect(textFieldView.multilineTextField.text) == "old value";
                expect(textFieldView.value as? String) == "old value";
            }
        }
    }
}
