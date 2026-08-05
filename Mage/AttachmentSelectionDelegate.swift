//
//  AttachmentSelectionDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 8/5/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//


import Foundation
import Persistence

public protocol AttachmentSelectionDelegate: AnyObject {
    func selectedAttachment(_ attachment: Attachment)

    func selectedUnsentAttachment(_ unsentAttachment: [AnyHashable: Any])

    func selectedNotCachedAttachment(
        _ attachment: Attachment,
        completionHandler: @escaping (Bool) -> Void
    )

    func attachmentFabTapped(
        _ attachment: Attachment,
        completionHandler: @escaping (Bool) -> Void
    )

    func attachmentFabTappedField(
        _ field: [AnyHashable: Any],
        completionHandler: @escaping (Bool) -> Void
    )
}

public extension AttachmentSelectionDelegate {
    func attachmentFabTapped(
        _ attachment: Attachment,
        completionHandler: @escaping (Bool) -> Void
    ) { }

    func attachmentFabTappedField(
        _ field: [AnyHashable: Any],
        completionHandler: @escaping (Bool) -> Void
    ) { }
}
