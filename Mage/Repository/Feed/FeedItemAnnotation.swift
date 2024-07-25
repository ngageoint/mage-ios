//
//  FeedItemAnnotation.swift
//  MAGE
//
//  Created by Dan Barela on 7/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

public class FeedItemAnnotation: NSObject, MKAnnotation {
    public var id: URL { feedItemId }
    var view: MKAnnotationView?
    
    public var feedItemId: URL
    public var coordinate: CLLocationCoordinate2D
    public var iconURL: URL?
    public var feedId: URL?
    
    init(feedItem: FeedItem) {
        self.coordinate = feedItem.coordinate
        self.feedItemId = feedItem.objectID.uriRepresentation()
        self.iconURL = feedItem.iconURL
        self.feedId = feedItem.feed?.objectID.uriRepresentation()
    }
    
    static func ==(lhs: FeedItemAnnotation, rhs: FeedItemAnnotation) -> Bool {
        lhs.feedItemId == rhs.feedItemId
    }
    
    open override var hash: Int {
        id.hashValue
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let annotation = object as? FeedItemAnnotation {
            return self == annotation
        }
        return false
    }
}
