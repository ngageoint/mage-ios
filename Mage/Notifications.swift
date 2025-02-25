//
//  Notifications.swift
//  MAGE
//
//  Created by Daniel Barela on 4/11/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialViews

extension Notification.Name {
    public static let SnackbarNotification = Notification.Name("Snackbar")
}

struct SnackbarNotification {
    var snackbarModel: SnackbarModel?
}

class Example {
    init () {
        let w = 0
    }
}
