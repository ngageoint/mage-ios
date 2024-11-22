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

@testable import MAGE

class DropdownFieldViewTests: XCTestCase {
    
    var controller: UIViewController!
    var window: UIWindow!;
    
    var dropdownFieldView: DropdownFieldView!
    var view: UIView!
    var field: [String: Any]!
    
    @MainActor
    override func setUp() {
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
        
        window = TestHelpers.getKeyWindowVisible();
        window.rootViewController = controller;
        
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
    
    @MainActor
    func testNoInitialValue() {
        dropdownFieldView = DropdownFieldView(field: field);
        dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dropdownFieldView)
        dropdownFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.dropdownFieldView.isEmpty()) == true;
    }
    
    @MainActor
    func testInitialValueSet() {
        dropdownFieldView = DropdownFieldView(field: field, value: "Hello");
        dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dropdownFieldView)
        dropdownFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.dropdownFieldView.isEmpty()) == false;
    }
    
    @MainActor
    func testSetValueViaInput() {
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
    
    @MainActor
    func testRequiredFieldShouldShowStatus() {
        field[FieldKey.required.key] = true;
        dropdownFieldView = DropdownFieldView(field: field);
        dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dropdownFieldView)
        dropdownFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.dropdownFieldView.isEmpty()) == true;
        dropdownFieldView.setValid(dropdownFieldView.isValid());
    }
    
    @MainActor
    func testRequiredFieldShouldShowStatusAfterValueHasBeenAdded() {
        field[FieldKey.required.key] = true;
        dropdownFieldView = DropdownFieldView(field: field);
        dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(dropdownFieldView)
        dropdownFieldView.autoPinEdgesToSuperviewEdges();
        
        expect(self.dropdownFieldView.isEmpty()) == true;
        dropdownFieldView.setValid(dropdownFieldView.isValid());
        dropdownFieldView.setValue("purple");
        expect(self.dropdownFieldView.getValue()) == "purple";
        expect(self.dropdownFieldView.isEmpty()) == false;
        dropdownFieldView.setValid(dropdownFieldView.isValid());
    }
}
