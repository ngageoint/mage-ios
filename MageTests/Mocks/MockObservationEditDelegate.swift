//
//  MockObservationEditDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class MockObservationEditDelegate: ObservationEditDelegate {
    
    var editCancelCalled = false;
    var editCancelCoordinator: NSObject?;
    
    var editCompleteCalled = false;
    var editCompleteCoordinator: NSObject?;
    var editCompleteObservation: Observation?;
    
    func editCancel(_ coordinator: NSObject) {
        editCancelCalled = true;
    }
    
    func editComplete(_ observation: Observation, coordinator: NSObject) {
        editCompleteCalled = true;
        editCompleteObservation = observation;
        editCompleteCoordinator = coordinator;
    }
}
