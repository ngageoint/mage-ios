//
//  FeatureItemDefinition.swift
//  MAGE
//
//  Created by Dan Barela on 6/24/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition

extension DataSources {
    static let featureItem: FeatureItemDefinition = FeatureItemDefinition.definition
}

final
class FeatureItemDefinition: DataSourceDefinition, Sendable {
    var mappable: Bool = true 

    var color: UIColor = .magenta

    var imageName: String?
    
    var systemImageName: String? = "face.smiling"

    var key: String = "feature"

    var name: String = "Features"

    var fullName: String = "Features"

    static let definition = FeatureItemDefinition()
    private init() { }
}
