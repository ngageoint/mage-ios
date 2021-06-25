//
//  MockObservationFormReorderDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/24/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class MockObservationFormReorderDelegate: ObservationFormReorderDelegate {
    var cancelReorderCalled = false;
    var formsReorderedCalled = false;
    var formsReorderedObservation: Observation?;
    
    func cancelReorder() {
        cancelReorderCalled = true;
    }
    
    func formsReordered(observation: Observation) {
        formsReorderedCalled = true;
    }
}
