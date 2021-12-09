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
    var overlays: Set<AnyHashable>?
}
