//
//  FeedDefinition.swift
//  MAGE
//
//  Created by Dan Barela on 6/17/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition

extension DataSources {
    static let feedItem: FeedItemDefinition = FeedItemDefinition.definition
}

class FeedItemDefinition: DataSourceDefinition {
    var mappable: Bool = true

    var color: UIColor = .magenta

    var imageName: String?
    
    var systemImageName: String? = "face.smiling"

    var key: String = "feed"

    var name: String = "Feeds"

    var fullName: String = "Feeds"

    static let definition = FeedItemDefinition()
    private init() { }
}
