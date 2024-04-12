//
//  MapNotifications.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import DataSourceDefinition

extension Notification.Name {
    public static let MapLongPress = Notification.Name("MapLongPress")
    public static let FocusMapOnItem = Notification.Name("FocusMapOnItem")
    public static let FocusMapAtLocation = Notification.Name("FocusMapAtLocation")
}

struct FocusMapOnItemNotification {
    var item: (any Locatable)?
    var zoom: Bool = false
    var mapName: String?
    var definition: (any DataSourceDefinition)?
}
