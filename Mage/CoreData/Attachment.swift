//
//  Attachment.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import CoreData

@objc public class Attachment: NSManagedObject {
    
    @objc public static func attachment(json: [AnyHashable : Any], context: NSManagedObjectContext) -> Attachment? {
        let attachment = Attachment.mr_createEntity(in: context);
        attachment?.populate(json: json);
        return attachment;
    }
    
    @objc public func populate(json: [AnyHashable : Any]) {
        self.remoteId = json[AttachmentKey.id.key] as? String
        self.contentType = json[AttachmentKey.contentType.key] as? String
        self.url = json[AttachmentKey.url.key] as? String
        self.name = json[AttachmentKey.name.key] as? String
        self.size = json[AttachmentKey.size.key] as? NSNumber
        self.observationFormId = json[AttachmentKey.observationFormId.key] as? String
        self.fieldName = json[AttachmentKey.fieldName.key] as? String
        if let dirty = json[AttachmentKey.dirty.key] as? Bool {
            self.dirty = dirty;
        } else {
            self.dirty = false;
        }
        self.localPath = json[AttachmentKey.localPath.key] as? String
        
        if let lastModified = json[AttachmentKey.lastModified.key] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
            formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
            self.lastModified = formatter.date(from: lastModified);
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
}

//#import "Attachment.h"
//#import "NSDate+Iso8601.h"
//#import "StoredPassword.h"
//
//@class Observation;
//
//+ (Attachment *) attachmentForJson: (NSDictionary *) json inContext: (NSManagedObjectContext *) context;
//- (id) populateFromJson: (NSDictionary *) json;
//- (NSURL *) sourceURLWithSize:(NSInteger) size;
//
//@implementation Attachment
//
//+ (Attachment *) attachmentForJson: (NSDictionary *) json inContext: (NSManagedObjectContext *) context {
//    Attachment *attachment = [Attachment MR_createEntityInContext:context];
//    [attachment populateFromJson:json];
//    return attachment;
//}
//
//- (id) populateFromJson: (NSDictionary *) json {
//    [self setRemoteId:[json objectForKey:@"id"]];
//    [self setContentType:[json objectForKey:@"contentType"]];
//    [self setUrl:[json objectForKey:@"url"]];
//    [self setName: [json objectForKey:@"name"]];
//    [self setSize: [json objectForKey:@"size"]];
//    [self setObservationFormId: [json objectForKey:@"observationFormId"]];
//    [self setFieldName: [json objectForKey:@"fieldName"]];
//    id dirty = [json objectForKey:@"dirty"];
//    if (dirty != nil) {
//        [self setDirty:[NSNumber numberWithBool:[dirty boolValue]]];
//    } else {
//        [self setDirty:[NSNumber numberWithBool:NO]];
//    }
//    [self setLocalPath: [json objectForKey:@"localPath"]];
//
//    NSString *dateString = [json objectForKey:@"lastModified"];
//    if (dateString != nil) {
//        NSDate *date = [NSDate dateFromIso8601String:dateString];
//        [self setLastModified:date];
//    } else {
//        [self setLastModified:[NSDate date]];
//    }
//    id markedForDeletion = [json objectForKey:@"markedForDeletion"];
//    if (markedForDeletion != nil) {
//        [self setMarkedForDeletion:[markedForDeletion boolValue]];
//    } else {
//        [self setMarkedForDeletion:false];
//    }
//    return self;
//}
//
//- (NSURL *) sourceURLWithSize:(NSInteger) size {
//    if (self.localPath && [[NSFileManager defaultManager] fileExistsAtPath:self.localPath]) {
//        return [NSURL fileURLWithPath:self.localPath];
//    } else {
//        NSString *token = [StoredPassword retrieveStoredToken];
//        return [NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@&size=%ld", self.url, token, (long) size]];
//    }
//}
//
//@end
