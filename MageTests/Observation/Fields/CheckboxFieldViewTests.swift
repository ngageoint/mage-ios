//
//  EditCheckboxFieldView.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/28/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots

@testable import MAGE

class CheckboxFieldViewTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("CheckboxFieldView") {
            var controller: UIViewController!
            var window: UIWindow!;
            
            var checkboxFieldView: CheckboxFieldView!
            var view: UIView!
            var field: [String: Any]!
            
            beforeEach {
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                
                field = [
                    "title": "Field Title",
                    "name": "field8",
                    "id": 8
                ];
//                Nimble_Snapshots.setNimbleTolerance(0.0);
//                Nimble_Snapshots.recordAllSnapshots()
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
            }
            
            it("no initial value") {
                checkboxFieldView = CheckboxFieldView(field: field);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
//                expect(view).to(haveValidSnapshot());
            }
            
            it("initial value true") {
                checkboxFieldView = CheckboxFieldView(field: field, value: true);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
//                expect(view).to(haveValidSnapshot());
            }
            
            it("initial value false") {
                checkboxFieldView = CheckboxFieldView(field: field, value: false);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
//                expect(view).to(haveValidSnapshot());
            }
            
            it("set value later") {
                checkboxFieldView = CheckboxFieldView(field: field);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                checkboxFieldView.setValue(true);
//                expect(view).to(haveValidSnapshot());
            }
            
            it("set value simulated touch") {
                checkboxFieldView = CheckboxFieldView(field: field);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().setOn(true, forSwitchWithAccessibilityLabel: field["name"] as? String);
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("required") {
                field["required"] = true;
                checkboxFieldView = CheckboxFieldView(field: field);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                checkboxFieldView.setValue(true);
//                expect(view).to(haveValidSnapshot());
            }
            
            it("set valid false") {
                checkboxFieldView = CheckboxFieldView(field: field);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                checkboxFieldView.setValid(false);
//                expect(view).to(haveValidSnapshot());
            }
            
            it("set valid true after being invalid") {
                checkboxFieldView = CheckboxFieldView(field: field);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                checkboxFieldView.setValid(false);
                checkboxFieldView.setValid(true);
//                expect(view).to(haveValidSnapshot());
            }
            
            it("required field is invalid if false") {
                field[FieldKey.required.key] = true;
                
                checkboxFieldView = CheckboxFieldView(field: field);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                expect(checkboxFieldView.isEmpty()) == true;
                expect(checkboxFieldView.isValid(enforceRequired: true)) == false;
                checkboxFieldView.setValid(checkboxFieldView.isValid());
//                expect(view).to(haveValidSnapshot());
            }
            
            it("required field is valid if true") {
                field[FieldKey.required.key] = true;
                
                checkboxFieldView = CheckboxFieldView(field: field);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                checkboxFieldView.setValue(true);
                expect(checkboxFieldView.isEmpty()) == false;
                expect(checkboxFieldView.isValid(enforceRequired: true)) == true;
                checkboxFieldView.setValid(checkboxFieldView.isValid());
//                expect(view).to(haveValidSnapshot());
            }
            
            it("test delegate false value") {
                let delegate = MockFieldDelegate();
                checkboxFieldView = CheckboxFieldView(field: field, delegate: delegate);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();

                controller.view.addSubview(view);
                checkboxFieldView.switchValueChanged(theSwitch: checkboxFieldView.checkboxSwitch);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? Bool) == false;
            }
            
            it("test delegate true value") {
                let delegate = MockFieldDelegate();
                checkboxFieldView = CheckboxFieldView(field: field, delegate: delegate);
                checkboxFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                checkboxFieldView.setValue(true);
                checkboxFieldView.switchValueChanged(theSwitch: checkboxFieldView.checkboxSwitch);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? Bool) == true;
            }
        }
    }
}
