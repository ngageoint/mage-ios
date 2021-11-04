//
//  Role+CoreDataProperties.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/19/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Role {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Role> {
        return NSFetchRequest<Role>(entityName: "Role")
    }
    @NSManaged var permissions: [String]?
    @NSManaged var remoteId: String?
    @NSManaged var users: Set<User>?
}

// MARK: Generated accessors for users
extension Role {
    
    @objc(addUsersObject:)
    @NSManaged public func addToUsers(_ value: User)
    
    @objc(removeUsersObject:)
    @NSManaged public func removeFromUsers(_ value: User)
    
    @objc(addUsers:)
    @NSManaged public func addToUsers(_ values: Set<User>)
    
    @objc(removeUsers:)
    @NSManaged public func removeFromUsers(_ values: Set<User>)
}
