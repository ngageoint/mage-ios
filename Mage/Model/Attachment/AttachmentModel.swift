//
//  AttachmentModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

// TODO: this is only a class so that it can be in a method marked @objc fix this later
@objc class AttachmentModel: NSObject, Identifiable {
    var id: URL {
        attachmentUri
    }
    
    @objc var attachmentUri: URL
    var unsent: Bool = false
    var formId: String?
    var remoteId: String?
    var url: String?
    var name: String?
    var size: NSNumber?
    var fieldName: String?
    var order: NSNumber = 0
    var dirty: Bool = false
    var localPath: String?
    var lastModified: Date?
    var contentType: String?
    @objc var markedForDeletion: Bool = false
    
    var urlWithToken: URL? {
        if let url = url {
            var url2 = URL(string: url)
            url2?.append(
                queryItems: [
                    URLQueryItem(name: "access_token", value: StoredPassword.retrieveStoredToken())
                ]
            )
            return url2
        }
        return nil
    }
//}
//
//extension AttachmentModel {
    init(attachment: Attachment) {
        attachmentUri = attachment.objectID.uriRepresentation()
        url = attachment.url
        formId = attachment.observationFormId
        remoteId = attachment.remoteId
        name = attachment.name
        size = attachment.size
        fieldName = attachment.fieldName
        order = attachment.order ?? 0
        dirty = attachment.dirty
        localPath = attachment.localPath
        lastModified = attachment.lastModified
        contentType = attachment.contentType
        markedForDeletion = attachment.markedForDeletion
    }
}
