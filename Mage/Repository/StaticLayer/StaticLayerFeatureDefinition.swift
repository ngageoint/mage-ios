//
//  StaticLayerFeatureDefinition.swift
//  MAGE
//
//  Created by Dan Barela on 7/1/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition

extension DataSources {
    static let staticLayerFeature: StaticLayerFeatureDefinition = StaticLayerFeatureDefinition.definition
}

class StaticLayerFeatureDefinition: DataSourceDefinition {
    var mappable: Bool = true

    var color: UIColor = .magenta

    var imageName: String?
    
    var systemImageName: String? = "face.smiling"

    var key: String = "staticLayer"

    var name: String = "Static layer"

    var fullName: String = "Static layer"

    static let definition = StaticLayerFeatureDefinition()
    private init() { }
}
