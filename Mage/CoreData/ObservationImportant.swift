//
//  ObservationImportant+CoreDataClass.m
//  mage-ios-sdk
//
//  Created by William Newman on 9/19/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData

@objc public class ObservationImportant : NSManagedObject {
    
    @objc public static func important(json: [String : Any], context: NSManagedObjectContext) -> ObservationImportant? {
        let important = ObservationImportant.mr_createEntity(in: context);
        important?.update(json: json);
        return important
    }
    
    @objc public func update(json: [String : Any]) {
        self.dirty = false
        self.important = true
        self.userId = json[ObservationImportantKey.userId.key] as? String
        self.reason = json[ObservationImportantKey.description.key] as? String;
        
        if let timestamp = json[ObservationImportantKey.timestamp.key] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone];
            formatter.timeZone = TimeZone(secondsFromGMT: 0)!;
            
            self.timestamp = formatter.date(from: timestamp);
        }
    }
}
