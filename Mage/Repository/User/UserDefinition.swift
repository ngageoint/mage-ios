//
//  UserDefinition.swift
//  MAGE
//
//  Created by Dan Barela on 6/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition

extension DataSources {
    static let user: UserDefinition = UserDefinition.definition
}

class UserDefinition: DataSourceDefinition {
    var mappable: Bool = true

    var color: UIColor = .magenta

    var imageName: String?
    
    var systemImageName: String? = "face.smiling"

    var key: String = "user"

    var name: String = "Users"

    var fullName: String = "Users"

    static let definition = UserDefinition()
    private init() { }
}
