//
//  ObservationActionsDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 1/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

extension Notification.Name {
    public static let ViewObservation = Notification.Name("ViewObservation")
}

@objc protocol ObservationActionsDelegate {
    @objc optional func viewObservation(_ observation: Observation);
    @objc optional func moreActionsTapped(_ observation: Observation);
    @objc optional func showFavorites(_ observation: Observation);
    @objc optional func favoriteObservation(_ observation: Observation, completion: ((Observation?) -> Void)?);
    @objc optional func getDirectionsToObservation(_ observation: Observation, sourceView: UIView?);
    @objc optional func copyLocation(_ locationString: String);
    @objc optional func makeImportant(_ observation: Observation, reason: String);
    @objc optional func removeImportant(_ observation: Observation);
    @objc optional func editObservation(_ observation: Observation);
    @objc optional func deleteObservation(_ observation: Observation);
    @objc optional func cancelAction();
    @objc optional func reorderForms(_ observation: Observation);
    @objc optional func viewUser(_ user: User);
}
