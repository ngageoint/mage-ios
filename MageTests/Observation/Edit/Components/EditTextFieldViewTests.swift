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

class MockStartPresenterDelegate: NSObject, ObservationEditListener {
    var fieldChangedCalled = false;
    var newValue: Any? = nil;
    func observationField(_ field: Any!, valueChangedTo value: Any!, reloadCell reload: Bool) {
        fieldChangedCalled = true;
        newValue = value;
    }
}

class EditTextFieldViewTests: QuickSpec {
    
    override func spec() {
        
        describe("EditTextFieldView Single Line") {
            
            var textFieldView: EditTextFieldView!
            var view: UIView!
            var field: NSMutableDictionary!
            
            beforeEach {
                field = ["title": "Field Title"];
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
            }
            
            it("no initial value") {
                textFieldView = EditTextFieldView(field: field);
 
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("initial value set") {
                textFieldView = EditTextFieldView(field: field, value: "Hello");
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("set value later") {
                textFieldView = EditTextFieldView(field: field);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValue("Hi")
                expect(view) == snapshot();
            }
            
            it("set valid false") {
                textFieldView = EditTextFieldView(field: field);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValid(false);
                expect(view) == snapshot();
            }
            
            it("set valid true after being invalid") {
                textFieldView = EditTextFieldView(field: field);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValid(false);
                textFieldView.setValid(true);
                expect(view) == snapshot();
            }
            
            it("required field is invalid if empty") {
                field.setValue(true, forKey: "required");
                textFieldView = EditTextFieldView(field: field);
                
                expect(textFieldView.isEmpty()) == true;
                expect(textFieldView.isValid(enforceRequired: true)) == false;
            }
            
            it("required field is valid if not empty") {
                field.setValue(true, forKey: "required");
                textFieldView = EditTextFieldView(field: field, value: "valid");
                
                expect(textFieldView.isEmpty()) == false;
                expect(textFieldView.isValid(enforceRequired: true)) == true;
            }
            
            it("required field has title which indicates required") {
                field.setValue(true, forKey: "required");
                textFieldView = EditTextFieldView(field: field);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(view) == snapshot();
            }
            
            it("test delegate") {
                let delegate = MockStartPresenterDelegate();
                textFieldView = EditTextFieldView(field: field, delegate: delegate);
                textFieldView.textFieldDidEndEditing(textFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
            }
        }
        
        describe("EditTextFieldView Multi Line") {
            
            var textFieldView: EditTextFieldView!
            var view: UIView!
            var field: NSDictionary!
            
            beforeEach {
                field = ["title": "Multi Line Field Title"];
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
            }
            
            it("no initial value") {
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("initial value set") {
                textFieldView = EditTextFieldView(field: field, value: "Hello", multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("set value later") {
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                
                textFieldView.setValue("Hi")
                expect(view) == snapshot();
            }
            
            it("set multi line value later") {
                textFieldView = EditTextFieldView(field: field, multiline: true);
                
                view.addSubview(textFieldView)
                textFieldView.autoPinEdgesToSuperviewEdges();
                view.autoPinEdge(.bottom, to: .bottom, of: textFieldView);
                textFieldView.setValue("Hi\nHello")
                
                expect(view) == snapshot();
            }
            
            it("test delegate") {
                let delegate = MockStartPresenterDelegate();
                textFieldView = EditTextFieldView(field: field, multiline: true, delegate: delegate);
                textFieldView.textViewDidEndEditing(textFieldView.multilineTextField.textView!);
                expect(delegate.fieldChangedCalled) == true;
            }
        }
    }
}
