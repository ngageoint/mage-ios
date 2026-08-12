//
//  PersistenceProtocol.swift
//  Persistence
//

@preconcurrency import CoreData

public enum StorageType {
    case persistent, inMemory
}

public enum PersistenceError: Error {
    case modelNotFound
}

@objc
public final class ObjCPersistenceResult: NSObject, Sendable {
    @objc public let success: Bool
    @objc public let persistenceError: NSError?
    @objc public let blockError: NSError?
    
    @objc
    public init(
        success: Bool = true,
        persistenceError: NSError? = nil,
        blockError: NSError? = nil
    ) {
        self.success = success
        self.persistenceError = persistenceError
        self.blockError = blockError
    }
    
    public convenience init<T>(from result: PersistenceResult<T>)
    where T: AnyObject & Sendable {
        self.init(
            success: result.success,
            persistenceError: result.persistenceError as NSError?,
            blockError: result.blockError as NSError?
        )
    }
}

public struct PersistenceResult<T: Sendable>: Sendable {
    public init(success: Bool, persistenceError: (any Error)? = nil, blockReturn: T? = nil, blockError: (any Error)? = nil) {
        self.success = success
        self.persistenceError = persistenceError
        self.blockError = blockError
        self.blockReturn = blockReturn
    }
    
    public let success: Bool
    public let persistenceError: Error?
    public let blockError: Error?
    public let blockReturn: T?
}

public protocol PersistenceProtocol: Sendable {
    var viewContext: NSManagedObjectContext { get }
    var writeContext: NSManagedObjectContext { get }
    
    func read<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async rethrows -> T
    func write<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T?
    ) async throws -> PersistenceResult<T>
    func background<T: Sendable>(
        name: String?,
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async rethrows -> PersistenceResult<T>
    
    func fetchAllSortedBy<T: NSManagedObject>(
        sortTerm: String,
        ascending: Bool,
        predicate: NSPredicate?,
        groupBy: String?,
        delegate: NSFetchedResultsControllerDelegate?
    ) async -> NSFetchedResultsController<T>
    where T: NSManagedObject & Sendable
    
}
