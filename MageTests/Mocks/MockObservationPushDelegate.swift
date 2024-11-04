//
//  MockObservationPushDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
@testable import MAGE

class MockObservationPushDelegate: NSObject, ObservationPushDelegate {
    var didPushCalled = false;
    var pushedObservation: Observation?;
    var success = false;
    var error: Error?
    
    func didPush(observation: Observation, success: Bool, error: Error?) {
        didPushCalled = true
        pushedObservation = observation
        self.success = success;
        self.error = error;
    }
    
    override var description: String {
        return "<\(type(of: self)): \ndidPushCalled = \(didPushCalled) \npushedObservation = \(pushedObservation == nil ? "nil" : "not nil") \nsuccess = \(success) \nerror = \(error?.localizedDescription ?? "nil")>"
    }
}
