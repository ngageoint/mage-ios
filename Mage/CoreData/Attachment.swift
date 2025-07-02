//
//  Attachment.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import CoreData

@objc public class Attachment: NSManagedObject {
    
    public static func attachment(json: [AnyHashable : Any], order: Int? = 0, context: NSManagedObjectContext) -> Attachment? {
        return context.performAndWait {
            let attachment = Attachment(context: context)
            attachment.populate(json: json, order: order)
            try? context.obtainPermanentIDs(for: [attachment])
            return attachment
        }
    }
    
    public func populate(json: [AnyHashable : Any], order: Int? = 0) {
        self.remoteId = json[AttachmentKey.id.key] as? String
        self.contentType = json[AttachmentKey.contentType.key] as? String
        self.url = json[AttachmentKey.url.key] as? String
        self.name = json[AttachmentKey.name.key] as? String
        self.size = json[AttachmentKey.size.key] as? NSNumber
        self.observationFormId = json[AttachmentKey.observationFormId.key] as? String
        self.fieldName = json[AttachmentKey.fieldName.key] as? String
        if let order = order {
            self.order = NSNumber(value:order)
        } else {
            self.order = 0
        }
        if let dirty = json[AttachmentKey.dirty.key] as? Bool {
            self.dirty = dirty;
        } else {
            self.dirty = false;
        }
        self.localPath = json[AttachmentKey.localPath.key] as? String
        
        if let lastModified = json[AttachmentKey.lastModified.key] as? String {
            self.lastModified = Date.ISO8601FormatStyle.gmtZeroDate(from: lastModified);
        } else {
            self.lastModified = Date();
        }
        
        if let markedForDeletion = json[AttachmentKey.markedForDeletion.key] as? Bool {
            self.markedForDeletion = markedForDeletion;
        } else {
            self.markedForDeletion = false;
        }
        
    }
    
    @objc public func sourceURL(size: NSInteger) -> URL? {
        if let localPath = self.localPath, FileManager.default.fileExists(atPath: localPath) {
            return URL(fileURLWithPath: localPath);
        } else {
            let token = StoredPassword.retrieveStoredToken();
            return URL(string: "\(self.url ?? "")?access_token=\(token ?? "")&size=\(size)")
        }
    }
    
    @objc public override func prepareForDeletion() {
        super.prepareForDeletion()
        // Delete the associated attachment from the filesystem
        if let localPath = self.localPath, FileManager.default.fileExists(atPath: localPath) {
            try? FileManager.default.removeItem(atPath: localPath)
        }
    }
}
