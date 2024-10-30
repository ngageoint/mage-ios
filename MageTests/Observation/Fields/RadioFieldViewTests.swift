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

@testable import MAGE

class RadioFieldViewTests: XCTestCase {
    
    var controller: UIViewController!
    var window: UIWindow!;
    
    var radioFieldView: RadioFieldView!
    var view: UIView!
    var field: [String: Any]!
    
    @MainActor
    override func setUp() {
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
    }
    
    @MainActor
    override func tearDown() {
        controller.dismiss(animated: false, completion: nil);
        window.rootViewController = nil;
        controller = nil;
    }
    
    @MainActor
    func testNoInitialValue() {
        radioFieldView = RadioFieldView(field: field);
        radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(radioFieldView)
        radioFieldView.autoPinEdgesToSuperviewEdges();
        
        controller.view.addSubview(view);
        expect(self.radioFieldView.isEmpty()) == true;
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testInitialValueSet() {
        radioFieldView = RadioFieldView(field: field, value: "Purple");
        radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(radioFieldView)
        radioFieldView.autoPinEdgesToSuperviewEdges();
        
        controller.view.addSubview(view);
        expect(self.radioFieldView.isEmpty()) == false;
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testSetValueViaInput() {
        let delegate = MockFieldDelegate();
        radioFieldView = RadioFieldView(field: field, delegate: delegate);
        radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(radioFieldView)
        radioFieldView.autoPinEdgesToSuperviewEdges();
        
        controller.view = view;
        tester().waitForView(withAccessibilityLabel: "field8 Purple radio");
        tester().tapView(withAccessibilityLabel: "field8 Purple radio")
        expect(self.radioFieldView.getValue()).to(equal("Purple"));
    }
    
    @MainActor
    func testRequiredFieldShouldShowStatus() {
        field[FieldKey.required.key] = true;
        radioFieldView = RadioFieldView(field: field);
        radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(radioFieldView)
        radioFieldView.autoPinEdgesToSuperviewEdges();
        
        controller.view.addSubview(view);
        expect(self.radioFieldView.isEmpty()) == true;
        radioFieldView.setValid(radioFieldView.isValid());
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testRequiredFieldShouldShowStatusAfterValueHasBeenAdded() {
        field[FieldKey.required.key] = true;
        radioFieldView = RadioFieldView(field: field);
        radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(radioFieldView)
        radioFieldView.autoPinEdgesToSuperviewEdges();
        
        controller.view.addSubview(view);
        expect(self.radioFieldView.isEmpty()) == true;
        radioFieldView.setValid(radioFieldView.isValid());
        radioFieldView.setValue("Purple");
        expect(self.radioFieldView.getValue()) == "Purple";
        expect(self.radioFieldView.isEmpty()) == false;
        radioFieldView.setValid(radioFieldView.isValid());
//                expect(view).to(haveValidSnapshot());
    }
}
