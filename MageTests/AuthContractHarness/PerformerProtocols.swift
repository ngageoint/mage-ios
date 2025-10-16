//
//  PerformerProtocols.swift
//  MAGE
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

protocol LegacyAuthPerformer {
    func perform(_ endpoint: AuthEndpoint) async -> HTTPResponse
}

protocol NewAuthPerformer {
    func perform(_ endpoint: AuthEndpoint) async -> HTTPResponse
}
