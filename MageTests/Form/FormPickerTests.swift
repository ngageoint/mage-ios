//
//  FormPickerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/30/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import OHHTTPStubs
import MaterialComponents.MaterialBottomSheet

@testable import MAGE

class MockFormPickerDelegate: FormPickedDelegate {
    var formPickedCalled = true;
    var pickedForm: [String : AnyHashable]?;
    var cancelSelectionCalled = false;
    
    func formPicked(form: [String : Any]) {
        formPickedCalled = true;
        pickedForm = form as? [String: AnyHashable];
    }
    
    func cancelSelection() {
        cancelSelectionCalled = true;
    }
}

class FormPickerTests: KIFSpec {
    
    override func spec() {
        
        describe("FormPickerTests") {
            
            var formPicker: FormPickerViewController!
            var window: UIWindow!;

            beforeEach {
                window = TestHelpers.getKeyWindowVisible();
                
                Nimble_Snapshots.setNimbleTolerance(0.0);
//                Nimble_Snapshots.recordAllSnapshots()
            }
            
            afterEach {
                formPicker.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                formPicker = nil;
            }
            
            it("initialized") {
                formPicker = FormPickerViewController(scheme: MAGEScheme.scheme());
                
                window.rootViewController = formPicker;
                
                expect(formPicker.view).to(haveValidSnapshot());
            }
            
            it("one form") {
                let forms: [[String: AnyHashable]] = [[
                    "name": "Suspect",
                    "description": "Information about a suspect",
                    "color": "#5278A2",
                    "id": 2
                ]]
                
                formPicker = FormPickerViewController(forms: forms, scheme: MAGEScheme.scheme());
                
                window.rootViewController = formPicker;
                
                expect(formPicker.view).to(haveValidSnapshot());
            }
            
            it("multiple forms") {
                let forms: [[String: AnyHashable]] = [[
                    "name": "Suspect",
                    "description": "Information about a suspect",
                    "color": "#5278A2",
                    "id": 2
                ], [
                    "name": "Vehicle",
                    "description": "Information about a vehicle",
                    "color": "#7852A2",
                    "id": 3
                ], [
                    "name": "Evidence",
                    "description": "Evidence form",
                    "color": "#52A278",
                    "id": 0
                ], [
                    "name": "Witness",
                    "description": "Information gathered from a witness",
                    "color": "#A25278",
                    "id": 1
                ], [
                    "name": "Location",
                    "description": "Detailed information about the scene",
                    "id": 4
                ]]
                
                formPicker = FormPickerViewController(forms: forms, scheme: MAGEScheme.scheme());
                
                window.rootViewController = formPicker;
                
                expect(formPicker.view).to(haveValidSnapshot());
            }
            
            it("as a sheet") {
                let forms: [[String: AnyHashable]] = [[
                    "name": "Vehicle",
                    "description": "Information about a vehicle",
                    "color": "#7852A2",
                    "id": 3
                ], [
                    "name": "Evidence",
                    "description": "Evidence form",
                    "color": "#52A278",
                    "id": 0
                ], [
                    "name": "Witness",
                    "description": "Information gathered from a witness",
                    "color": "#A25278",
                    "id": 1
                ], [
                    "name": "Location",
                    "description": "Detailed information about the scene",
                    "color": "#78A252",
                    "id": 4
                ],[
                    "name": "Suspect2",
                    "description": "Information about a suspect",
                    "color": "#5278A2",
                    "id": 2
                ], [
                    "name": "Vehicle2",
                    "description": "Information about a vehicle",
                    "color": "#7852A2",
                    "id": 3
                ], [
                    "name": "Evidence2",
                    "description": "Evidence form",
                    "color": "#52A278",
                    "id": 0
                ], [
                    "name": "Witness2",
                    "description": "Information gathered from a witness",
                    "color": "#A25278",
                    "id": 1
                ], [
                    "name": "Location2",
                    "description": "Detailed information about the scene",
                    "color": "#78A252",
                    "id": 4
                ], [
                    "name": "Suspect",
                    "description": "Information about a suspect",
                    "color": "#5278A2",
                    "id": 2
                ]]
                let delegate = MockFormPickerDelegate();

                formPicker = FormPickerViewController(delegate: delegate, forms: forms, scheme: MAGEScheme.scheme());
                
                let container = UIViewController();
                
                window.rootViewController = container;
                
                let bottomSheet: MDCBottomSheetController = MDCBottomSheetController(contentViewController: formPicker);
                container.present(bottomSheet, animated: true, completion: nil);
                tester().waitForView(withAccessibilityLabel: "Add A Form Table");
                tester().waitForCell(at: IndexPath(row: forms.count - 1, section: 0), in: viewTester().usingLabel("Add A Form Table").view as? UITableView);
                tester().waitForTappableView(withAccessibilityLabel: "Suspect");
                tester().tapView(withAccessibilityLabel: "Suspect");
                
                expect(delegate.formPickedCalled).to(beTrue());
                expect(delegate.pickedForm).to(equal(forms[9]));

                expect(formPicker.view).to(haveValidSnapshot());
            }
            // check constraints here
            it("should trigger the delegate") {
                
                let forms: [[String: AnyHashable]] = [[
                    "name": "Suspect",
                    "description": "Information about a suspect",
                    "color": "#5278A2",
                    "id": 2
                ], [
                    "name": "Vehicle",
                    "description": "Information about a vehicle",
                    "color": "#7852A2",
                    "id": 3
                ], [
                    "name": "Evidence",
                    "description": "Evidence form",
                    "color": "#52A278",
                    "id": 0
                ], [
                    "name": "Witness",
                    "description": "Information gathered from a witness",
                    "color": "#A25278",
                    "id": 1
                ], [
                    "name": "Location",
                    "description": "Detailed information about the scene",
                    "color": "#78A252",
                    "id": 4
                ]]
                
                let delegate = MockFormPickerDelegate();
                
                formPicker = FormPickerViewController(delegate: delegate, forms: forms, scheme: MAGEScheme.scheme());
                
                window.rootViewController = formPicker;
                
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                expect(delegate.cancelSelectionCalled).to(beTrue());
            }
            
            it("cancel button cancels") {
                let forms: [[String: AnyHashable]] = [[
                    "name": "Suspect",
                    "description": "Information about a suspect",
                    "color": "#5278A2",
                    "id": 2
                ]]
                
                formPicker = FormPickerViewController(forms: forms, scheme: MAGEScheme.scheme());
                
                window.rootViewController = formPicker;
                
                expect(formPicker.view).to(haveValidSnapshot());
            }
        }
    }
}
