//
//  MapAnnotationFocusedNotification.swift
//  MAGE
//
//  Created by Daniel Barela on 12/9/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapKit

extension Notification.Name {
    public static let DataSourceUpdated = Notification.Name("DataSourceUpdated")
}

struct MapAnnotationFocusedNotification {
    var annotation: MKAnnotation?
    var mapView: MKMapView?
}

struct MapItemsTappedNotification {
    var annotations: [Any]?
    var items: [Any]?
    var mapView: MKMapView?
}

struct DirectionsToItemNotification {
    var observation: Observation?
    var user: User?
    var feedItem: FeedItem?
    var location: CLLocation?
    var annotation: MKAnnotationView?
    var image: UIImage?
    var imageUrl: URL?
    var sourceView: UIView?
}

struct DataSourceUpdatedNotification {
    var key: String
    var updates: Int?
    var inserts: Int?
    var deletes: Int?
}
