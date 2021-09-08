//
//  MockObservationActionsDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/23/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class MockObservationActionsDelegate: ObservationActionsDelegate {
    var showFavoritesCalled = false;
    var favoriteCalled = false;
    var getDirectionsCalled = false;
    var getDirectionsToObservationsCalled = false;
    var makeImportantCalled = false;
    var makeImportantReason: String?;
    var removeImportantCalled = false;
    var locationStringCopied: String?;
    var copyLocationCalled = false;
    
    var observationSent: Observation?;
    
    func showFavorites(_ observation: Observation) {
        showFavoritesCalled = true;
        observationSent = observation;
    }
    
    func favoriteObservation(_ observation: Observation) {
        favoriteCalled = true;
        observationSent = observation;
    }
    
    func getDirections(_ observation: Observation, sourceView: UIView?) {
        getDirectionsCalled = true;
        observationSent = observation;
    }
    
    func getDirectionsToObservation(_ observation: Observation, sourceView: UIView? = nil) {
        getDirectionsToObservationsCalled = true;
        observationSent = observation;
    }
    
    func makeImportant(_ observation: Observation, reason: String) {
        makeImportantCalled = true;
        observationSent = observation;
        makeImportantReason = reason;
    }
    
    func removeImportant(_ observation: Observation) {
        removeImportantCalled = true;
        observationSent = observation;
    }
    
    func copyLocation(_ locationString: String) {
        copyLocationCalled = true;
        locationStringCopied = locationString;
    }
}
