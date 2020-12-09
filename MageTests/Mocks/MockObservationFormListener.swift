//
//  MockObservationFormListener.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/7/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class MockObservationFormListener: ObservationFormListener {
    var formUpdatedCalled = false;
    var formUpdatedForm: [String : Any]? = nil;
    var formUpdatedEventForm: [String: Any]? = nil;
    var formUpdatedIndex: Int? = nil;
    
    func formUpdated(_ form: [String : Any], eventForm: [String : Any], form index: Int) {
        print("form updated in the listener")
        formUpdatedCalled = true;
        formUpdatedForm = form;
        formUpdatedEventForm = eventForm;
        formUpdatedIndex = index;
    }
}
