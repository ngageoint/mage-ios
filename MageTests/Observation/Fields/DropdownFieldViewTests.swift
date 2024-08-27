//
//  DropdownFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/27/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots

@testable import MAGE

class DropdownFieldViewTests: KIFSpec {
    
    override func spec() {
        xdescribe("DropdownFieldView") {            
            var controller: UIViewController!
            var window: UIWindow!;
            
            var dropdownFieldView: DropdownFieldView!
            var view: UIView!
            var field: [String: Any]!

            controller = UIViewController();
            view = UIView(forAutoLayout: ());
            view.autoSetDimension(.width, toSize: 300);
            
            controller.view.addSubview(view);
            
            field = [
                "title": "Field Title",
                "name": "field8",
                "type": "dropdown",
                "id": 8
            ];
            
            beforeEach {
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                
                for subview in view.subviews {
                    subview.removeFromSuperview();
                }
                
//                Nimble_Snapshots.setNimbleTolerance(0.0);
//                Nimble_Snapshots.recordAllSnapshots()
            }
            
            afterEach {
                for subview in view.subviews {
                    subview.removeFromSuperview();
                }
            }
            
            it("no initial value") {
                dropdownFieldView = DropdownFieldView(field: field);
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(dropdownFieldView.isEmpty()) == true;
//                expect(view).to(haveValidSnapshot());
            }
            
            it("initial value set") {
                dropdownFieldView = DropdownFieldView(field: field, value: "Hello");
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(dropdownFieldView.isEmpty()) == false;

//                expect(view).to(haveValidSnapshot());
            }
            
            it("set value via input") {
                let delegate = MockFieldDelegate();
                dropdownFieldView = DropdownFieldView(field: field, delegate: delegate);
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
                dropdownFieldView.handleTap();
                expect(delegate.launchFieldSelectionViewControllerCalled).to(beTrue());
                expect(delegate.viewControllerToLaunch).to(beAnInstanceOf(SelectEditViewController.self));
            }
            
            it("required field should show status") {
                field[FieldKey.required.key] = true;
                dropdownFieldView = DropdownFieldView(field: field);
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(dropdownFieldView.isEmpty()) == true;
                dropdownFieldView.setValid(dropdownFieldView.isValid());
//                expect(view).to(haveValidSnapshot());
            }
            
            it("required field should show status after value has been added") {
                field[FieldKey.required.key] = true;
                dropdownFieldView = DropdownFieldView(field: field);
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(dropdownFieldView.isEmpty()) == true;
                dropdownFieldView.setValid(dropdownFieldView.isValid());
                dropdownFieldView.setValue("purple");
                expect(dropdownFieldView.getValue()) == "purple";
                expect(dropdownFieldView.isEmpty()) == false;
                dropdownFieldView.setValid(dropdownFieldView.isValid());
//                expect(view).to(haveValidSnapshot());
            }
        }
    }
}
