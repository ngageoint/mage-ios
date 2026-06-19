//
//  ObjCCoreDataPersistence.swift
//  Persistence
//
//  Created by Daniel Barela on 6/19/26.
//

import Foundation
import CoreData

@objc
public final class ObjCCoreDataPersistence: NSObject, @unchecked Sendable {
    
    @objc
    public static func write(
        _ block: @Sendable @escaping (NSManagedObjectContext) -> PersistenceResult?,
        completion: @Sendable @escaping (PersistenceResult) -> Void
    ) {
        let persistence = PersistenceContainer.shared.get()
        
        Task {
            let wrapped = ObjCWriteBlock(block)
            do {
                let result = try await persistence.write { context in
                    try wrapped.block(context)
                }
                
                DispatchQueue.main.async {
                    completion(result)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(
                        PersistenceResult(success: false, persistenceError: error as NSError)
                    )
                }
            }
        }
    }
    
    @available(*, deprecated, message: "Returning non sendable is deprecated")
    @objc
    public static func syncRead(
        _ block: @escaping (NSManagedObjectContext) -> Any?
    ) -> Any? {
        let persistence = PersistenceContainer.shared.get()
        let block = block
        do {
            let wrapped = ObjCReadBlockAny(block)
            let viewContext = persistence.viewContext
            let result = try viewContext.performAndWait{
                try wrapped.block(viewContext)
            }
            return result
        } catch {
            return nil
        }
    }
    
}

private final class ObjCWriteBlock: @unchecked Sendable {
    let block: (NSManagedObjectContext) throws -> PersistenceResult?
    
    init(_ block: @Sendable @escaping (NSManagedObjectContext) throws -> PersistenceResult?) {
        self.block = block
    }
}

private final class ObjCReadBlock: @unchecked Sendable {
    let block: @Sendable (NSManagedObjectContext) throws -> Sendable?
    
    init(_ block: @Sendable @escaping (NSManagedObjectContext) throws -> Sendable?) {
        self.block = block
    }
}

@available(*, deprecated, message: "Returning non sendable is deprecated")
private final class ObjCReadBlockAny: @unchecked Sendable {
    let block: (NSManagedObjectContext) throws -> Any?
    
    init(_ block: @escaping (NSManagedObjectContext) throws -> Any?) {
        self.block = block
    }
}
