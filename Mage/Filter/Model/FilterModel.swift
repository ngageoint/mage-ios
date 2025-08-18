//
//  FilterModel.swift
//  MAGE
//
//  Created by James McDougall on 8/18/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct FilterModel: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var subtitle: String
}
