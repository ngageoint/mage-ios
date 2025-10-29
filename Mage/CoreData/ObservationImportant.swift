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
        let important = ObservationImportant(context: context);
        important.update(json: json);
        try? context.obtainPermanentIDs(for: [important])
        return important
    }
    
    @objc public func update(json: [String : Any]) {
        self.dirty = false
        self.important = true
        self.userId = json[ObservationImportantKey.userId.key] as? String
        self.reason = json[ObservationImportantKey.description.key] as? String;
        
        if let timestamp = json[ObservationImportantKey.timestamp.key] as? String {
            self.timestamp = Date.ISO8601FormatStyle.gmtZeroDate(from: timestamp);
        }
    }
}
