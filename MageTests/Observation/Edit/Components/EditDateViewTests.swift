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

extension EditDateView {
    func getDatePicker() -> UIDatePicker {
        return datePicker;
    }
}

class EditDateViewTests: KIFSpec {
    
    override func spec() {
        
        describe("EditDateFieldView") {
            
            var dateFieldView: EditDateView!
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
                window.backgroundColor = .systemBackground;
                
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .white;
                window.makeKeyAndVisible();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                NSDate.setDisplayGMT(false);
                
                field = [
                    "title": "Date Field",
                    "id": 8,
                    "name": "field8"
                ];
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
            }
            
            it("non edit mode") {
                dateFieldView = EditDateView(field: field, editMode: false, value: "2013-06-22T08:18:20.000Z");
                
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                tester().waitForView(withAccessibilityLabel: "\(field["name"] as? String ?? "") Label");
                expect(view) == maybeSnapshot();
            }
            
            it("no initial value") {
                dateFieldView = EditDateView(field: field);
                
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                expect(view) == maybeSnapshot();
            }
            
            it("initial value set") {
                dateFieldView = EditDateView(field: field, value: "2013-06-22T08:18:20.000Z");

                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                expect(view) == maybeSnapshot();
            }
            
            it("set value later") {
                dateFieldView = EditDateView(field: field);

                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();

                dateFieldView.setValue( "2013-06-22T08:18:20.000Z")
                expect(view) == maybeSnapshot();
            }
            
            it("set value with touch inputs") {
                let delegate = MockFieldDelegate()

                dateFieldView = EditDateView(field: field, delegate: delegate, value: "2020-11-01T08:18:00.000Z");
                
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().tapView(withAccessibilityLabel: field["name"] as? String);
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: (field["name"] as? String ?? "") + " Date Picker");
                tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .forwardFromCurrentValue);
                tester().tapView(withAccessibilityLabel: "Done");
                
                let formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
                formatter.locale = Locale(identifier: "en_US_POSIX");
                
                let date = formatter.date(from: "2020-11-02T14:00:00.000Z")!;

                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? String) == formatter.string(from: date);
                expect(dateFieldView.textField.text).to(equal((date as NSDate).formattedDisplay()));
                expect(view) == maybeSnapshot();
            }
            
            it("set value with touch inputs in GMT") {
                NSDate.setDisplayGMT(true);
                let delegate = MockFieldDelegate()
                
                dateFieldView = EditDateView(field: field, delegate: delegate, value: "2020-11-01T08:18:00.000Z");
                
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().tapView(withAccessibilityLabel: field["name"] as? String);
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: (field["name"] as? String ?? "") + " Date Picker");
                tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .forwardFromCurrentValue);
                tester().tapView(withAccessibilityLabel: "Done");
                
                let formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
                formatter.locale = Locale(identifier: "en_US_POSIX");
                
                let date = formatter.date(from: "2020-11-02T07:00:00.000Z")!;
                
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? String) == formatter.string(from: date);
                expect(dateFieldView.textField.text).to(equal((date as NSDate).formattedDisplay()));
            }
            
            it("set value with touch inputs then cancel") {
                let delegate = MockFieldDelegate()
                
                let value = "2020-11-01T08:18:00.000Z";
                
                dateFieldView = EditDateView(field: field, delegate: delegate, value: value);
                
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().tapView(withAccessibilityLabel: field["name"] as? String);
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: (field["name"] as? String ?? "") + " Date Picker");
                tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .forwardFromCurrentValue);
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                let formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
                formatter.locale = Locale(identifier: "en_US_POSIX");
                
                let date = formatter.date(from: value)!;
                
                expect(delegate.fieldChangedCalled) == false;
                expect(dateFieldView.textField.text).to(equal((date as NSDate).formattedDisplay()));
            }
            
            it("set clear the text field via touch") {
                let delegate = MockFieldDelegate()
                
                let value = "2020-11-01T08:18:00.000Z";
                
                dateFieldView = EditDateView(field: field, delegate: delegate, value: value);
                
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().tapView(withAccessibilityLabel: field["name"] as? String);
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: (field["name"] as? String ?? "") + " Date Picker");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().clearTextFromFirstResponder();
                tester().tapView(withAccessibilityLabel: "Done");
                
                let formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
                formatter.locale = Locale(identifier: "en_US_POSIX");
                
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue).to(beNil());
                expect(dateFieldView.textField.text).to(equal(""));
            }

            it("set valid false") {
                dateFieldView = EditDateView(field: field);

                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();

                dateFieldView.setValid(false);
                expect(view) == maybeSnapshot();
            }

            it("set valid true after being invalid") {
                dateFieldView = EditDateView(field: field);

                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();

                dateFieldView.setValid(false);
                dateFieldView.setValid(true);
                expect(view) == maybeSnapshot();
            }

            it("required field is invalid if empty") {
                field[FieldKey.required.key] = true;
                dateFieldView = EditDateView(field: field);

                expect(dateFieldView.isEmpty()) == true;
                expect(dateFieldView.isValid(enforceRequired: true)) == false;
            }

            it("required field is valid if not empty") {
                field[FieldKey.required.key] = true;
                dateFieldView = EditDateView(field: field, value: "2013-06-22T08:18:20.000Z");

                expect(dateFieldView.isEmpty()) == false;
                expect(dateFieldView.isValid(enforceRequired: true)) == true;
            }

            it("required field has title which indicates required") {
                field[FieldKey.required.key] = true;
                dateFieldView = EditDateView(field: field);

                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();

                expect(view) == maybeSnapshot();
            }

            it("test delegate") {
                let formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
                formatter.locale = Locale(identifier: "en_US_POSIX");
                
                let delegate = MockFieldDelegate()
                dateFieldView = EditDateView(field: field, delegate: delegate, value: "2013-06-22T08:18:20.000Z");
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                let newDate = Date(timeIntervalSince1970: 10000000);
                dateFieldView.textFieldDidBeginEditing(dateFieldView.textField);
                dateFieldView.getDatePicker().date = newDate;
                dateFieldView.dateChanged();
                dateFieldView.textFieldDidEndEditing(dateFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? String) == formatter.string(from: newDate);
                expect(view) == maybeSnapshot();
            }
            
            it("done button should send nil as new value") {
                let formatter = DateFormatter();
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
                formatter.locale = Locale(identifier: "en_US_POSIX");
                
                let delegate = MockFieldDelegate()
                dateFieldView = EditDateView(field: field, delegate: delegate, value: "2013-06-22T08:18:20.000Z");
                view.addSubview(dateFieldView)
                dateFieldView.autoPinEdgesToSuperviewEdges();
                dateFieldView.textField.text = "";
                dateFieldView.textFieldShouldClear(dateFieldView.textField);
                expect(delegate.fieldChangedCalled) == true;
                expect(dateFieldView.textField.text) == "";
                expect(dateFieldView.getValue()).to(beNil());
            }
        }
    }
}
