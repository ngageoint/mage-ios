//
//  GeoPackageDataSourceDefinition.swift
//  MAGE
//
//  Created by Dan Barela on 6/18/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition

extension DataSources {
    static let geoPackage: GeoPackageDefinition = GeoPackageDefinition.definition
}

class GeoPackageDefinition: DataSourceDefinition {
    var mappable: Bool = true

    var color: UIColor = .magenta

    var imageName: String?
    
    var systemImageName: String? = "face.smiling"

    var key: String = "geopackage"

    var name: String = "GeoPackage"

    var fullName: String = "GeoPackage"

    static let definition = GeoPackageDefinition()
    private init() { }
}
