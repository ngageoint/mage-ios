//
//  RepositoryManager.swift
//  MAGE
//
//  Created by Daniel Barela on 3/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

// This is the equivalent of adding repositories to the environment in SwiftUI
class RepositoryManager: ObservableObject {
    static let shared = RepositoryManager()

    var observationsTileRepository: ObservationsTileRepository?
}
