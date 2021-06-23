//
//  RadioFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/26/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class RadioFieldViewTests: KIFSpec {
    
    override func spec() {
        describe("RadioFieldView") {
            
            var controller: UIViewController!
            var window: UIWindow!;
            
            var radioFieldView: RadioFieldView!
            var view: UIView!
            var field: [String: Any]!
            
            beforeEach {
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                
                field = [
                    "title": "Field Title",
                    "name": "field8",
                    "type": "radio",
                    "id": 8,
                    "choices": [
                        [
                            "value": 0,
                            "id": 0,
                            "title": "Purple"
                        ],
                        [
                            "value": 1,
                            "id": 1,
                            "title": "Blue"
                        ],
                        [
                            "value": 2,
                            "id": 2,
                            "title": "Green"
                        ]
                    ]
                ];
                
                window.rootViewController = controller;
                
                Nimble_Snapshots.setNimbleTolerance(0.0);
//                Nimble_Snapshots.recordAllSnapshots()
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
            }
            
            it("non edit mode") {
                radioFieldView = RadioFieldView(field: field, editMode: false, value: "Purple");
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(view).to(haveValidSnapshot());
            }
            
            it("no initial value") {
                radioFieldView = RadioFieldView(field: field);
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(radioFieldView.isEmpty()) == true;
                expect(view).to(haveValidSnapshot());
            }
            
            it("initial value set") {
                radioFieldView = RadioFieldView(field: field, value: "Purple");
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(radioFieldView.isEmpty()) == false;
                expect(view).to(haveValidSnapshot());
            }
            
            it("set value via input") {
                let delegate = MockFieldDelegate();
                radioFieldView = RadioFieldView(field: field, delegate: delegate);
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view = view;
                tester().waitForView(withAccessibilityLabel: "field8 Purple radio");
                tester().tapView(withAccessibilityLabel: "field8 Purple radio")
                expect(radioFieldView.getValue()).to(equal("Purple"));
            }
            
            it("required field should show status") {
                field[FieldKey.required.key] = true;
                radioFieldView = RadioFieldView(field: field);
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(radioFieldView.isEmpty()) == true;
                radioFieldView.setValid(radioFieldView.isValid());
                expect(view).to(haveValidSnapshot());
            }
            
            it("required field should show status after value has been added") {
                field[FieldKey.required.key] = true;
                radioFieldView = RadioFieldView(field: field);
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(radioFieldView.isEmpty()) == true;
                radioFieldView.setValid(radioFieldView.isValid());
                radioFieldView.setValue("Purple");
                expect(radioFieldView.getValue()) == "Purple";
                expect(radioFieldView.isEmpty()) == false;
                radioFieldView.setValid(radioFieldView.isValid());
                expect(view).to(haveValidSnapshot());
            }
        }
    }
}
