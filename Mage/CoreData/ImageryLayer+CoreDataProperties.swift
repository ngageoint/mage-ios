//
//  ImageryLayer+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 10/1/19.
//  Copyright © 2019 National Geospatial-Intelligence Agency. All rights reserved.
//
//

import Foundation
import CoreData

extension ImageryLayer {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageryLayer> {
        return NSFetchRequest<ImageryLayer>(entityName: "ImageryLayer")
    }
    
    @NSManaged var format: String?
    @NSManaged var options: [AnyHashable:Any]?
    @NSManaged var isSecure: Bool
}
