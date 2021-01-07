//
//  ObservationActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 1/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc protocol ObservationActionsDelegate {
    @objc optional func showFavorites(_ observation: Observation);
    @objc optional func favorite(_ observation: Observation);
    @objc optional func getDirections(_ observation: Observation);
    @objc optional func makeImportant(_ observation: Observation, reason: String);
    @objc optional func removeImportant(_ observation: Observation);
    @objc optional func editObservation(_ observation: Observation);
    @objc optional func deleteObservation(_ observation: Observation);
    @objc optional func cancelAction();
}
