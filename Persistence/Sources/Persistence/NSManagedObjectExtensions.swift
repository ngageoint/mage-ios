//
//  File.swift
//  Persistence
//
//  Created by Daniel Barela on 6/19/26.
//

import Foundation
import CoreData

public extension NSManagedObject {
    @objc
    static func findFirst(inContext: NSManagedObjectContext) -> Self? {
        do {
            return try inContext.fetchFirst(
                Self.self,
                sortBy: nil,
                predicate: nil
            )
        } catch {
            return nil
        }
    }
    
    @objc
    static func findFirst(with: NSPredicate? = nil, sortedBy: [NSSortDescriptor]? = nil, in context: NSManagedObjectContext) -> Self? {
        do {
            return try context.fetchFirst(
                Self.self,
                sortBy: sortedBy,
                predicate: with
            )
        } catch {
            return nil
        }
    }
    
    @objc
    static func createEntity(inContext: NSManagedObjectContext) -> Self {
        let e = Self.init(context: inContext)
        try? inContext.obtainPermanentIDs(for: [e])
        return e
    }
}
