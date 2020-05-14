//
//  EditGeometryViewTests.swift
//  MAGE
//
//  Created by Daniel Barela on 5/12/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class MockGeometryFieldDelegate: NSObject, ObservationEditListener {
    var fieldChangedCalled = false;
    var newValue: String? = nil;
    func observationField(_ field: Any!, valueChangedTo value: Any!, reloadCell reload: Bool) {
        fieldChangedCalled = true;
        newValue = value as? String;
    }
}

class EditGeometryViewTests: QuickSpec {
    
    override func spec() {
        
        describe("EditGeometryView") {
            
            var geometryFieldView: EditGeometryView!
            var view: UIView!
            var field: NSMutableDictionary!
            
            beforeEach {
                field = ["title": "Field Title"];
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
            }
            
            it("no initial value") {
                geometryFieldView = EditGeometryView(field: field);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("initial value set as a point") {
                let point = SFPoint(x: 40.008483, andY: -105.267755);
                geometryFieldView = EditGeometryView(field: field, value: point, accuracy: 1.487235, provider: "gps");

                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }

//
//            it("set value later") {
//                textFieldView = EditTextFieldView(field: field);
//
//                view.addSubview(textFieldView)
//                textFieldView.autoPinEdgesToSuperviewEdges();
//
//                textFieldView.setValue("Hi")
//                expect(view) == snapshot();
//            }
//
//            it("set valid false") {
//                textFieldView = EditTextFieldView(field: field);
//
//                view.addSubview(textFieldView)
//                textFieldView.autoPinEdgesToSuperviewEdges();
//
//                textFieldView.setValid(false);
//                expect(view) == snapshot();
//            }
//
//            it("set valid true after being invalid") {
//                textFieldView = EditTextFieldView(field: field);
//
//                view.addSubview(textFieldView)
//                textFieldView.autoPinEdgesToSuperviewEdges();
//
//                textFieldView.setValid(false);
//                textFieldView.setValid(true);
//                expect(view) == snapshot();
//            }
//
//            it("required field is invalid if empty") {
//                field.setValue(true, forKey: "required");
//                textFieldView = EditTextFieldView(field: field);
//
//                expect(textFieldView.isEmpty()) == true;
//                expect(textFieldView.isValid(enforceRequired: true)) == false;
//            }
//
//            it("required field is valid if not empty") {
//                field.setValue(true, forKey: "required");
//                textFieldView = EditTextFieldView(field: field, value: "valid");
//
//                expect(textFieldView.isEmpty()) == false;
//                expect(textFieldView.isValid(enforceRequired: true)) == true;
//            }
//
//            it("required field has title which indicates required") {
//                field.setValue(true, forKey: "required");
//                textFieldView = EditTextFieldView(field: field);
//
//                view.addSubview(textFieldView)
//                textFieldView.autoPinEdgesToSuperviewEdges();
//
//                expect(view) == snapshot();
//            }
//
//            it("test delegate") {
//                let delegate = MockTextFieldDelegate();
//                textFieldView = EditTextFieldView(field: field, delegate: delegate);
//                view.addSubview(textFieldView)
//                textFieldView.autoPinEdgesToSuperviewEdges();
//
//                textFieldView.textField.text = "new value";
//                textFieldView.textFieldDidEndEditing(textFieldView.textField);
//                expect(delegate.fieldChangedCalled) == true;
//                expect(delegate.newValue) == "new value";
//                expect(view) == snapshot();
//            }
        }
      
    }
}
