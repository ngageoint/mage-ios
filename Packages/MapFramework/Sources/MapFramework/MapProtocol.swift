//
//  MapProtocol.swift
//  MAGE
//
//  Created by Daniel Barela on 4/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@MainActor
protocol MapProtocol {
    var mixins: MapMixins { get set }
    var mapState: MapState { get }
    var name: String { get set }
    var notificationOnTap: NSNotification.Name { get set }
    var notificationOnLongPress: NSNotification.Name { get set }
}
