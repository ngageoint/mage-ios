//
//  PersistenceProtocol.swift
//  Persistence
//
//  Created by Daniel Barela on 6/18/26.
//

@preconcurrency import CoreData

public enum StorageType {
    case persistent, inMemory
}

public enum PersistenceError: Error {
    case modelNotFound
}

@objc
public final class PersistenceResult: NSObject, Sendable {
    @objc public let success: Bool
    @objc public let persistenceError: NSError?
    @objc public let blockError: NSError?
    @objc public let blockReturn: Sendable?
    
    @objc
    public init(success: Bool = true, persistenceError: NSError? = nil, blockReturn: Sendable? = nil, blockError: NSError? = nil) {
        self.success = success
        self.persistenceError = persistenceError
        self.blockReturn = blockReturn
        self.blockError = blockError
    }
}

public protocol PersistenceProtocol: Sendable {
    var viewContext: NSManagedObjectContext { get }
    var writeContext: NSManagedObjectContext { get }
    
    func read<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async rethrows -> T
    func write<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T?
    ) async throws -> PersistenceResult
    func background<T: Sendable>(
        name: String?,
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async rethrows -> PersistenceResult
    
    func fetchAllSortedBy<T: NSManagedObject>(
        sortTerm: String,
        ascending: Bool,
        predicate: NSPredicate?,
        groupBy: String?,
        delegate: NSFetchedResultsControllerDelegate?
    ) async -> NSFetchedResultsController<T>
    where T: NSManagedObject & Sendable

}
