//
//  FeedItem+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 6/2/20.
//  Copyright © 2020 National Geospatial-Intelligence Agency. All rights reserved.
//
//

import Foundation
import CoreData

public extension FeedItem {
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<FeedItem> {
        return NSFetchRequest<FeedItem>(entityName: "FeedItem")
    }
    
    @NSManaged var remoteId: String?
    @NSManaged var geometry: Data?
    @NSManaged var feed: Feed?
    @NSManaged var properties: Any?
    @NSManaged var temporalSortValue: NSNumber?;
    
}
