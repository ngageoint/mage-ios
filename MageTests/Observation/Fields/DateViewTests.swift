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
//import Nimble_Snapshots

@testable import MAGE

extension DateView {
    func getDatePicker() -> UIDatePicker {
        return datePicker;
    }
}

class DateViewTests: XCTestCase {
        
    var dateFieldView: DateView!
    var field: [String: Any]!
    
    var view: UIView!
    var controller: UIViewController!
    var window: UIWindow!;
    
    let formatter = DateFormatter();

    @MainActor
    override func setUp() {
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        
        controller = UIViewController();
        view = UIView(forAutoLayout: ());
        view.autoSetDimension(.width, toSize: 375);
        view.backgroundColor = .white;
        
        controller.view.addSubview(view);
        
        window = TestHelpers.getKeyWindowVisible();
        window.rootViewController = controller;
        
        NSDate.setDisplayGMT(false);
        
        field = [
            "title": "Date Field",
            "id": 8,
            "name": "field8"
        ];
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
    }
    
    @MainActor
    override func tearDown() {
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
    }
    
    func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
        
//        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Force UTC
//        
//        if let date = formatter.date(from: dateString) {
//            return date
//        } else {
//            print("❌ Failed to parse date: \(dateString)")
//            return nil
//        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm z"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Force UTC
        return formatter.string(from: date)
    }
    
    func formatDateToLocal(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm z" // Ensure timezone is included
        formatter.timeZone = TimeZone.current // ✅ Convert to system's timezone (CDT in your case)

        return formatter.string(from: date)
    }

    func convertUITextToComparableFormat(_ text: String?) -> String? {
        guard let text = text else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm z" // Assume UI displays this format
        formatter.timeZone = TimeZone.current // ✅ Assume the UI is already localized

        if let date = formatter.date(from: text) {
            return formatDateToLocal(date) // Convert UI string to a normalized format
        }

        return nil
    }

    
    @MainActor
    func testNoInitialValue() {
        dateFieldView = DateView(field: field);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
    }

//    "2020-11-01T08:18:00.000Z" -> 4
//    "2013-06-22T08:18:20.000Z" -> 6
    
//    "2013-06-22T08:18:00.000Z" -> 1
//    "2020-11-02T14:00:00.000Z" -> 1
//    "2020-11-02T07:00:00.000Z" -> 1
    
    struct TestDates {
        static let default2013 = "2013-06-22T08:18:20.000Z"
        static let default2020 = "2020-11-01T08:18:00.000Z"
        
        /// Convert a test date string to a `Date` object
        static func date(from string: String) -> Date? {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Handle milliseconds
            return formatter.date(from: string)
        }
    }

    
    @MainActor
    func testInitialValueSet() {
        dateFieldView = DateView(field: field, value: TestDates.default2013)
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme())
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges()
        
        tester().waitForView(withAccessibilityLabel: field["name"] as? String)
        
        guard let expectedDate = parseDate("2013-06-22T08:18:00.000Z") else {
            XCTFail("❌ Failed to parse expected date.")
            return
        }
        
        let formattedExpectedDate = formatDateToLocal(expectedDate) // ✅ Convert to CDT format
        let formattedActualDate = convertUITextToComparableFormat(self.dateFieldView.textField.text) // ✅ Convert UI date format
        
        // ✅ Compare both formatted values
        expect(formattedActualDate).to(equal(formattedExpectedDate))
    }
    
    @MainActor
    func testSetValueLater() {
        dateFieldView = DateView(field: field)
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme())
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges()
        
        // ✅ Set the value using the default test date
        dateFieldView.setValue(TestDates.default2013)
        
        // ✅ Convert the expected date to local time zone format
        guard let expectedDate = TestDates.date(from: TestDates.default2013) else {
            XCTFail("❌ Failed to parse expected date.")
            return
        }

        let formattedExpectedDate = formatDateToLocal(expectedDate) // ✅ Convert to CDT format
        let formattedActualDate = convertUITextToComparableFormat(self.dateFieldView.textField.text) // ✅ Convert UI date format
        
        // ✅ Compare both formatted values
        expect(formattedActualDate).to(equal(formattedExpectedDate))
    }
    
    @MainActor
    func testSetValueLaterAsAny() {
        dateFieldView = DateView(field: field);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        
        dateFieldView.setValue(TestDates.default2013 as Any?)
        
        // ✅ Convert the expected date to local time zone format
        guard let expectedDate = TestDates.date(from: TestDates.default2013) else {
            XCTFail("❌ Failed to parse expected date.")
            return
        }

        let formattedExpectedDate = formatDateToLocal(expectedDate) // ✅ Convert to CDT format
        let formattedActualDate = convertUITextToComparableFormat(self.dateFieldView.textField.text) // ✅ Convert UI date format
        
        // ✅ Compare both formatted values
        expect(formattedActualDate).to(equal(formattedExpectedDate))
    }
    
    @MainActor
    func testSetvalueWithTouchInputs() {
        let delegate = MockFieldDelegate()
        
        dateFieldView = DateView(field: field, delegate: delegate, value: TestDates.default2020);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: field["name"] as? String);
        tester().tapView(withAccessibilityLabel: field["name"] as? String);
        tester().waitForView(withAccessibilityLabel: (field["name"] as? String ?? "") + " Date Picker");
        tester().selectDatePickerValue(["Nov 2", "8", "00", "AM"], with: .forwardFromCurrentValue);
        tester().tapView(withAccessibilityLabel: "Done");
        
        // ✅ Ensure Delegate Triggered
        expect(delegate.fieldChangedCalled).to(beTrue())

        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        
        let date = formatter.date(from: "2020-11-02T14:00:00.000Z")!;
        
        let expectedFormattedDate = formatDateToLocal(date)  // Convert to UI time zone

        // ✅ Compare with UI text field value
        expect(self.dateFieldView.textField.text).to(equal(expectedFormattedDate))
    }
    
    @MainActor
    func testSetValueWithTouchInputsInGMT() {
        NSDate.setDisplayGMT(true);
        let delegate = MockFieldDelegate()
        
        dateFieldView = DateView(field: field, delegate: delegate, value: TestDates.default2020);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        
        tester().waitForAnimationsToFinish();
        
        tester().waitForView(withAccessibilityLabel: field["name"] as? String);
        tester().tapView(withAccessibilityLabel: field["name"] as? String);
        tester().waitForView(withAccessibilityLabel: (field["name"] as? String ?? "") + " Date Picker");
        
        tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .forwardFromCurrentValue);
        tester().tapView(withAccessibilityLabel: "Done");
        
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        print("what time zone \(NSTimeZone.system)")
        let date = formatter.date(from: "2020-11-02T07:00:00.000Z")!;
        // IMPORTANT: THIS IS TO CORRECT FOR A BUG IN KIF, YOU MUST COMPARE AGAINST THE DATE YOU SET
        // PLUS THE OFFSET FROM GMT OR IT WILL NOT WORK
        // IF THIS BUG IS CLOSED YOU CAN REMOVE THIS LINE: https://github.com/kif-framework/KIF/issues/1214
        //                print("how many seconds from gmt are we \(TimeZone.current.secondsFromGMT())")
        //                date.addTimeInterval(TimeInterval(-TimeZone.current.secondsFromGMT(for: date)));
        expect(delegate.fieldChangedCalled) == true;
        expect(delegate.newValue as? String) == formatter.string(from: date);
        expect(self.dateFieldView.textField.text).to(equal((date as NSDate).formattedDisplay()));
    }
    
    @MainActor
    func testSetValueWithTouchInputsThenCancel() {
        let delegate = MockFieldDelegate()
        
        let value = TestDates.default2020;
        
        dateFieldView = DateView(field: field, delegate: delegate, value: value);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: field["name"] as? String);
        tester().tapView(withAccessibilityLabel: field["name"] as? String);
        tester().waitForView(withAccessibilityLabel: (field["name"] as? String ?? "") + " Date Picker");
        tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .forwardFromCurrentValue);
        tester().tapView(withAccessibilityLabel: "Cancel");
        
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        
        let date = formatter.date(from: value)!;
        
        expect(delegate.fieldChangedCalled) == false;
        expect(self.dateFieldView.textField.text).to(equal((date as NSDate).formattedDisplay()));
    }
    
    // this test is finicky
    @MainActor
    func testSetClearTheTextFieldViaTouch() {
        let delegate = MockFieldDelegate()
        
        let value = TestDates.default2020;
        
        dateFieldView = DateView(field: field, delegate: delegate, value: value);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        
        
        tester().waitForView(withAccessibilityLabel: field["name"] as? String);
        tester().waitForTappableView(withAccessibilityLabel: field["name"] as? String);
        tester().tapView(withAccessibilityLabel: field["name"] as? String);
        tester().waitForView(withAccessibilityLabel: (field["name"] as? String ?? "") + " Date Picker");
        tester().clearTextFromFirstResponder();
        tester().tapView(withAccessibilityLabel: "Done");
        
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        
        expect(delegate.fieldChangedCalled) == true;
        expect(delegate.newValue).to(beNil());
        expect(self.dateFieldView.textField.text).to(equal(""));
    }
    
    @MainActor
    func testSetValidFalse() {
        dateFieldView = DateView(field: field);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        
        dateFieldView.setValid(false);
    }
    
    @MainActor
    func testSetValidTrueAfterBeingInvalid() {
        dateFieldView = DateView(field: field);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        
        dateFieldView.setValid(false);
        dateFieldView.setValid(true);
    }
    
    @MainActor
    func testRequiredFieldIsInvalidIfEmpty() {
        field[FieldKey.required.key] = true;
        dateFieldView = DateView(field: field);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.dateFieldView.isEmpty()) == true;
        expect(self.dateFieldView.isValid(enforceRequired: true)) == false;
    }
    
    @MainActor
    func testRequiredFieldIsValidIfNotEmpty() {
        field[FieldKey.required.key] = true;
        dateFieldView = DateView(field: field, value: TestDates.default2013);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.dateFieldView.isEmpty()) == false;
        expect(self.dateFieldView.isValid(enforceRequired: true)) == true;
    }
    
    @MainActor
    func testRequiredFieldHasTitleWhichIndicatesRequired() {
        field[FieldKey.required.key] = true;
        dateFieldView = DateView(field: field);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
    }
    
    @MainActor
    func testDelegate() {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        
        let delegate = MockFieldDelegate()
        dateFieldView = DateView(field: field, delegate: delegate, value: TestDates.default2013);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        let newDate = Date(timeIntervalSince1970: 10000000);
        dateFieldView.textFieldDidBeginEditing(dateFieldView.textField);
        dateFieldView.getDatePicker().date = newDate;
        dateFieldView.dateChanged();
        dateFieldView.textFieldDidEndEditing(dateFieldView.textField);
        expect(delegate.fieldChangedCalled) == true;
        expect(delegate.newValue as? String) == formatter.string(from: newDate);
    }
    
    @MainActor
    func testDoneButotnShouldSendNilAsNewValue() {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        
        let delegate = MockFieldDelegate()
        dateFieldView = DateView(field: field, delegate: delegate, value: TestDates.default2013);
        dateFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        view.addSubview(dateFieldView)
        dateFieldView.autoPinEdgesToSuperviewEdges();
        dateFieldView.textField.text = "";
        _ = dateFieldView.textFieldShouldClear(dateFieldView.textField);
        expect(delegate.fieldChangedCalled) == true;
        expect(self.dateFieldView.textField.text) == "";
        expect(self.dateFieldView.getValue()).to(beNil());
    }
}
