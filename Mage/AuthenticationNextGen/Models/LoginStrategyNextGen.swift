//
//  LoginStrategyNextGen.swift
//  MAGE
//
//  Created by Brent Michalski on 7/16/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

protocol LoginStrategyNextGen {
    var displayName: String { get }
    func login(username: String, password: String) async throws -> UserNextGen
}
