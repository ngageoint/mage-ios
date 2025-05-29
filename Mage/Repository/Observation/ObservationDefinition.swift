//
//  ObservationDefinition.swift
//  MAGE
//
//  Created by Dan Barela on 6/7/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition

enum DataSources {
}

extension DataSources {
    static let observation: ObservationDefinition = ObservationDefinition.definition
}

class ObservationDefinition: DataSourceDefinition {
    var mappable: Bool = true

    var color: UIColor = .magenta

    var imageName: String?
    
    var systemImageName: String? = "face.smiling"

    var key: String = "observations"

    var name: String = "Observations"

    var fullName: String = "Observations"

    static let definition = ObservationDefinition()
    private init() { }
}
