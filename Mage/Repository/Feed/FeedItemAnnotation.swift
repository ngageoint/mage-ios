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
    public var remoteId: String?
    public var simpleFeature: SFGeometry?
    
    public override var dataSource: any DataSourceDefinition {
        get {
            DataSources.feedItem // ERROR: Main actor-isolated conformance of 'FeedItemDefinition' to 'DataSourceDefinition' cannot be used in nonisolated context; this is an error in the Swift 6 language mode
        }
        set { }
    }
    
    init(feedItem: FeedItem) {
        super.init(coordinate: feedItem.coordinate, itemKey: feedItem.objectID.uriRepresentation().absoluteString)
        self.iconURL = feedItem.iconURL
        self.remoteId = feedItem.remoteId
        self.simpleFeature = feedItem.simpleFeature
        self.id = feedItem.objectID.uriRepresentation().absoluteString
    }
}
