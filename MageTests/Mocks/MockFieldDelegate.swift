//
//  MOckFIeldDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class MockFieldDelegate: NSObject, ObservationEditListener {
    var fieldChangedCalled = false;
    var newValue: Any? = nil;
    var fieldSelectedCalled = false;
    var selectedField: Any? = nil;
    func observationField(_ field: Any!, valueChangedTo value: Any!, reloadCell reload: Bool) {
        fieldChangedCalled = true;
        newValue = value;
    }
    func fieldSelected(_ field: Any!) {
        fieldSelectedCalled = true;
        selectedField = field;
    }
}
