//
//  Notifications.swift
//  MAGE
//
//  Created by Daniel Barela on 4/11/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

// TODO: - BRENT: Rename these when cleaning up
extension Notification.Name {
    public static let SnackbarNotification = Notification.Name("Snackbar")
}

struct SnackbarNotification {
    var snackbarModel: AlertModel?
}

public struct AlertModel {
    public let title: String?
    public let message: String?
    public let actionText: String?
    public let action: (() -> Void)?
    public let cancelText: String?

    public init(
        title: String? = nil,
        message: String?,
        actionText: String? = nil,
        action: (() -> Void)? = nil,
        cancelText: String? = "OK"
    ) {
        self.title = title
        self.message = message
        self.actionText = actionText
        self.action = action
        self.cancelText = cancelText
    }
}
