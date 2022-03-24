//
//  ObservationPushDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 11/18/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

protocol ObservationPushDelegate where Self: NSObject {
    func didPush(observation: Observation, success: Bool, error: Error?);
}
