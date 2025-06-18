//
//  MultiDropdownFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 2/24/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots

@testable import MAGE

class MultiDropdownFieldViewTests: KIFSpec {
    
    override func spec() {
        
        describe("MultiDropdownFieldView") {
            var controller: UIViewController!
            
            var multidropdownFieldView: MultiDropdownFieldView!
            var view: UIView!
            var field: [String: Any]!
            
            var window: UIWindow!;
            controller = UIViewController();
            view = UIView(forAutoLayout: ());
            view.autoSetDimension(.width, toSize: 300);
            controller.view.addSubview(view);
            
            beforeEach {
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                                
                field = [
                    "title": "Field Title",
                    "name": "field8",
                    "type": "dropdown",
                    "id": 8
                ];
                
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
            
            it("initial value set with multiple values") {
                multidropdownFieldView = MultiDropdownFieldView(field: field, value: ["Hello", "hi"]);
                multidropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(multidropdownFieldView)
                multidropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(multidropdownFieldView.isEmpty()) == false;
//                expect(view).to(haveValidSnapshot());
            }
            
            it("non edit mode multiple values") {
                multidropdownFieldView = MultiDropdownFieldView(field: field, editMode: false, value: ["Hello", "hi"]);
                multidropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(multidropdownFieldView)
                multidropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(multidropdownFieldView.isEmpty()) == false;
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("set value later") {
                multidropdownFieldView = MultiDropdownFieldView(field: field);
                multidropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(multidropdownFieldView)
                multidropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(multidropdownFieldView.isEmpty()) == true;
                multidropdownFieldView.setValue(["green", "purple"]);
                expect(multidropdownFieldView.isEmpty()) == false;
//                expect(view).to(haveValidSnapshot());
            }
            
            it("multi required field should show status") {
                field[FieldKey.required.key] = true;
                multidropdownFieldView = MultiDropdownFieldView(field: field);
                multidropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(multidropdownFieldView)
                multidropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(multidropdownFieldView.isEmpty()) == true;
                multidropdownFieldView.setValid(multidropdownFieldView.isValid());
//                expect(view).to(haveValidSnapshot());
            }
        }
    }
}
