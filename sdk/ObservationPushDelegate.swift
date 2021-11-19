//
//  ObservationPushDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 11/18/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public protocol ObservationPushDelegate where Self: NSObject {
    @objc func didPush(observation: Observation, success: Bool, error: Error?);
}
