//
//  FeedItemAnnotation.swift
//  MAGE
//
//  Created by Dan Barela on 7/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit
import DataSourceDefinition
import MapFramework

public class FeedItemAnnotation: DataSourceAnnotation {
    var view: MKAnnotationView?
    
    public var iconURL: URL?
    
    public override var dataSource: any DataSourceDefinition {
        get {
            DataSources.feedItem
        }
        set { }
    }
    
    init(feedItem: FeedItem) {
        super.init(coordinate: feedItem.coordinate, itemKey: feedItem.objectID.uriRepresentation().absoluteString)
        self.iconURL = feedItem.iconURL
        self.id = feedItem.objectID.uriRepresentation().absoluteString
    }
}
