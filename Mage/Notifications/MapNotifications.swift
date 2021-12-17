//
//  MapAnnotationFocusedNotification.swift
//  MAGE
//
//  Created by Daniel Barela on 12/9/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct MapAnnotationFocusedNotification {
    var annotation: MKAnnotation?
}

struct MapItemsTappedNotification {
    var annotations: Set<AnyHashable>?
    var items: [Any]?
}

struct DirectionsToItemNotification {
    var observation: Observation?
    var user: User?
    var feedItem: FeedItem?
}
