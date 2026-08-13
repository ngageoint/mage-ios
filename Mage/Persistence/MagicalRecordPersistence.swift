//
//  MagicalRecordPersistence.swift
//  MAGE
//
//  Created by Daniel Barela on 6/18/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Persistence
import MagicalRecord

public final class MagicalRecordPersistence: PersistenceProtocol {
    
    public let viewContext: NSManagedObjectContext
    public let writeContext: NSManagedObjectContext
    
    public init() {
        MagicalRecord.setupMageCoreDataStack()
        MagicalRecord.setLoggingLevel(.verbose)
        
        viewContext = .mr_default()
        writeContext = .mr_rootSaving()
    }
    
    func tearDownStack() {
        MagicalRecord.deleteCoreDataStack()
    }
}

extension MagicalRecordPersistence {
    
    public func readSync<T>(
        _ block: @escaping @Sendable (NSManagedObjectContext) -> T
    ) -> T {
        return viewContext.performAndWait {
            block(viewContext)
        }
    }
    
    public func read<T>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async rethrows -> T where T : Sendable {
        let context = viewContext
        
        return try await context.perform {
            try block(context)
        }
    }
    
    public func write<T>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T?
    ) async throws -> PersistenceResult<T> where T : Sendable {
        await withCheckedContinuation { continuation in
            var blockError: Error?
            var blockReturn: T?
            MagicalRecord.save { context in
                do {
                    blockReturn = try block(context)
                } catch {
                    blockError = error
                }
            } completion: { contextDidSave, error in
                continuation.resume(
                    returning: PersistenceResult<T>(
                        success: contextDidSave,
                        persistenceError: error as? NSError,
                        blockReturn: blockReturn,
                        blockError: blockError as? NSError
                    )
                )
            }
        }
    }
    
    public func background<T>(
        name: String?,
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async rethrows -> PersistenceResult<T> where T : Sendable {
        await withCheckedContinuation { continuation in
            var blockError: Error?
            var blockReturn: T?
            MagicalRecord.save { context in
                context.name = name
                do {
                    blockReturn = try block(context)
                } catch {
                    blockError = error
                }
            } completion: { contextDidSave, error in
                continuation.resume(
                    returning: PersistenceResult<T>(
                        success: contextDidSave,
                        persistenceError: error as? NSError,
                        blockReturn: blockReturn,
                        blockError: blockError as? NSError
                    )
                )
            }
        }
    }
    
    public func fetchAllSortedBy<T: NSManagedObject>(
        sortTerm: String,
        ascending: Bool,
        predicate: NSPredicate?,
        groupBy: String?,
        delegate: NSFetchedResultsControllerDelegate?
    ) async -> NSFetchedResultsController<T>
    where T: NSManagedObject & Sendable {
        T.mr_fetchAllSorted(
            by: sortTerm,
            ascending: ascending,
            with: predicate,
            groupBy: groupBy,
            delegate: delegate,
            in: viewContext
        ) as! NSFetchedResultsController<T>
    }
    
    @MainActor
    public func makeFetchedChangesStream<T: CoreDataDomainModelConvertible> (
        request: @escaping @Sendable () -> NSFetchRequest<T.Entity>,
        sectionNameKeyPath: String?
    ) throws -> FetchedResultsChangesAsyncStream<T> {
        let context = viewContext
        return try FetchedResultsChangesAsyncStream<T>(
            fetchRequest: request(),
            context: context,
            sectionNameKeyPath: sectionNameKeyPath
        )
    }
}
