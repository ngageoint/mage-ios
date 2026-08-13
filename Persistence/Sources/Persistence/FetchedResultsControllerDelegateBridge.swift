// 
//     
//  FetchedResultsControllerDelegateBridge.swift
//  Persistence
//
// 

import CoreData

@MainActor
final class FetchedResultsControllerDelegateBridge<T: CoreDataDomainModelConvertible>: NSObject, @MainActor NSFetchedResultsControllerDelegate, Sendable {
    
    typealias Entity = T.Entity
    
    private let continuation:
    AsyncStream<FetchedResultsChange<T>>.Continuation
    
    private weak var frc: NSFetchedResultsController<Entity>?
    
    init(
        frc: NSFetchedResultsController<Entity>,
        continuation: AsyncStream<FetchedResultsChange<T>>.Continuation
    ) {
        self.frc = frc
        self.continuation = continuation
    }
    
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {}
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        
        guard let object = anObject as? Entity else { return }
        switch type {
            
        case .insert:
            if let newIndexPath {
                continuation
                    .yield(.insert(newIndexPath, T(from: object)))
            }
            
        case .delete:
            if let indexPath {
                continuation.yield(.delete(indexPath, T(from: object)))
            }
            
        case .update:
            if let indexPath {
                continuation.yield(.update(indexPath, T(from: object)))
            }
            
        case .move:
            if let indexPath, let newIndexPath {
                continuation.yield(.move(indexPath, newIndexPath))
            }
            
        @unknown default:
            break
        }
    }
    
    deinit {
        continuation.finish()
    }
}
