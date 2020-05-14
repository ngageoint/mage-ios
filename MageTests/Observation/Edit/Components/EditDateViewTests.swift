//
//  EditDateFieldViewTests.swift
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

class MockDateFieldDelegate: NSObject, ObservationEditListener {
    var fieldChangedCalled = false;
    var newValue: String? = nil;
    func observationField(_ field: Any!, valueChangedTo value: Any!, reloadCell reload: Bool) {
        fieldChangedCalled = true;
        newValue = value as? String;
    }
}

extension EditDateView {
    func getDatePicker() -> UIDatePicker {
        return datePicker;
    }
}

class EditDateViewTests: QuickSpec {
    
    override func spec() {
        
        describe("EditDateFieldView") {
            
            var dateFieldView: EditDateView!
            var view: UIView!
            var field: NSMutableDictionary!
            
            beforeEach {
                field = ["title": "Date Field"];
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
            }
            
            it("no initial value") {
                dateFieldView = EditDateView(field: field);
                
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("initial value set") {
                dateFieldView = EditDateView(field: field, value: "2013-06-22T08:18:20.000Z");
                
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == snapshot();
            }
            
            it("set value later") {
                dateFieldView = EditDateView(field: field);

                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();

                dateFieldView.setValue( "2013-06-22T08:18:20.000Z")
                expect(view) == snapshot();
            }

            it("set valid false") {
                dateFieldView = EditDateView(field: field);

                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();

                dateFieldView.setValid(false);
                expect(view) == snapshot();
            }

            it("set valid true after being invalid") {
                dateFieldView = EditDateView(field: field);

                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();

                dateFieldView.setValid(false);
                dateFieldView.setValid(true);
                expect(view) == snapshot();
            }

            it("required field is invalid if empty") {
                field.setValue(true, forKey: "required");
                dateFieldView = EditDateView(field: field);

                expect(dateFieldView.isEmpty()) == true;
                expect(dateFieldView.isValid(enforceRequired: true)) == false;
            }

            it("required field is valid if not empty") {
                field.setValue(true, forKey: "required");
                dateFieldView = EditDateView(field: field, value: "2013-06-22T08:18:20.000Z");

                expect(dateFieldView.isEmpty()) == false;
                expect(dateFieldView.isValid(enforceRequired: true)) == true;
            }

            it("required field has title which indicates required") {
                field.setValue(true, forKey: "required");
                dateFieldView = EditDateView(field: field);

                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();

                expect(view) == snapshot();
            }

            it("test delegate") {
                let formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
                formatter.locale = Locale(identifier: "en_US_POSIX");
                
                let delegate = MockDateFieldDelegate()
                dateFieldView = EditDateView(field: field, delegate: delegate, value: "2013-06-22T08:18:20.000Z");
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                let newDate = Date(timeIntervalSince1970: 10000000);
                dateFieldView.textFieldDidBeginEditing(dateFieldView.textField);
                dateFieldView.getDatePicker().date = newDate;
                dateFieldView.dateChanged();
                dateFieldView.textFieldDidEndEditing(dateFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue) == formatter.string(from: newDate);
                expect(view) == snapshot();
            }
        }
    }
}
