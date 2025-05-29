//
//  MapNotifications.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition
import MapKit

public extension Notification.Name {
    static let MapLongPress = Notification.Name("MapLongPress")
    static let FocusMapOnItem = Notification.Name("FocusMapOnItem")
    static let FocusMapAtLocation = Notification.Name("FocusMapAtLocation")
    static let MapItemsTapped = Notification.Name("MapItemsTapped")
}

public struct FocusMapOnItemNotification {
    public init(item: (any Locatable)? = nil, zoom: Bool = false, mapName: String? = nil, definition: (any DataSourceDefinition)? = nil) {
        self.item = item
        self.zoom = zoom
        self.mapName = mapName
        self.definition = definition
    }
    
    public var item: (any Locatable)?
    public var zoom: Bool = false
    public var mapName: String?
    public var definition: (any DataSourceDefinition)?
}

public struct MapItemsTappedNotification {
    public init(annotations: [Any]? = nil, items: [Any]? = nil, itemKeys: [String: [String]]? = nil, mapView: MKMapView? = nil) {
        self.annotations = annotations
        self.items = items
        self.itemKeys = itemKeys
        self.mapView = mapView
    }
    
    public var annotations: [Any]?
    public var items: [Any]?
    public var itemKeys: [String: [String]]?
    public var mapView: MKMapView?
}
