//
//  MOckFIeldDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class MockFieldDelegate: NSObject, ObservationEditListener, FieldSelectionDelegate, ObservationFormFieldListener {
    
    var launchFieldSelectionViewControllerCalled = false;
    var viewControllerToLaunch: UIViewController? = nil;
    var fieldChangedCalled = false;
    var newValue: Any? = nil;
    var fieldSelectedCalled = false;
    var selectedField: Any? = nil;
    func fieldValueChanged(_ field: [String : Any], value: Any?) {
        print("field value changed in delegate")
        fieldChangedCalled = true;
        newValue = value;
    }
    func fieldSelected(_ field: [String : Any]) {
        fieldSelectedCalled = true;
        selectedField = field;
    }
    func launchFieldSelectionViewController(viewController: UIViewController) {
        launchFieldSelectionViewControllerCalled = true;
        viewControllerToLaunch = viewController;
    }
}
