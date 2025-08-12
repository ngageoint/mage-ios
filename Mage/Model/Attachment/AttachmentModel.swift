//
//  AttachmentModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

// TODO: this is only a class so that it can be in a method marked @objc fix this later
@objc public class AttachmentModel: NSObject, Identifiable {
    public var id: URL {
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

    init(attachment: Attachment) {
        // Ensure we don't store a URI from a temporary objectID
        if attachment.objectID.isTemporaryID {
            try? attachment.managedObjectContext?.obtainPermanentIDs(for: [attachment])
        }
        
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

extension AttachmentModel {
    // Centralized remote URL lookup
    var remoteURL: URL? {
        url.flatMap(URL.init(string:))
    }

    var localFileURL: URL? {
        AttachmentPath.localURL(fromStored: localPath, fileName: name)
    }

    // Centralized local URL healing (formerly "healedLocalURL")
    var healedLocalURL: URL? {
        AttachmentPath.localURL(fromStored: localPath, fileName: name)
    }

    // Prefer local if present, else remote (formerly "bestDisplayURL")
    var bestDisplayURL: URL? {
        healedLocalURL ?? remoteURL
    }

    private var _ctype: String { (contentType ?? "").lowercased() }

    var isImage: Bool { _ctype.hasPrefix("image/") }
    var isVideo: Bool { _ctype.hasPrefix("video/") }
    var isAudio: Bool { _ctype.hasPrefix("audio/") }
}
