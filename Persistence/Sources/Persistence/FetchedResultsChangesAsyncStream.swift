// 
//     
//  FetchedResultsChangesAsyncStream.swift
//  Persistence
//
// 


import CoreData

@MainActor
public final class FetchedResultsChangesAsyncStream<T: CoreDataDomainModelConvertible>: NSObject {
    public typealias Entity = T.Entity
    
    public let stream:AsyncStream<FetchedResultsChange<T>>
    
    private let frc: NSFetchedResultsController<Entity>
    
    private var delegateBridge:FetchedResultsControllerDelegateBridge<T>?
    private let continuation: AsyncStream<FetchedResultsChange<T>>.Continuation
        
    public init(
        fetchRequest: NSFetchRequest<Entity>,
        context: NSManagedObjectContext,
        sectionNameKeyPath: String?
    ) throws {
        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil
        )
        
        let stream = AsyncStream.makeStream(of: FetchedResultsChange<T>.self)
        
        self.stream = stream.stream
        self.continuation = stream.continuation
        
        self.frc = frc
        super.init()
        
        self.delegateBridge = FetchedResultsControllerDelegateBridge<T>(
            frc: frc,
            continuation: continuation
        )
        
        frc.delegate = delegateBridge
        
        do {
            try self.frc.performFetch()
            
            let initial = self.frc.fetchedObjects?.map {
                T(from: $0)
            } ?? []
            
            continuation.yield(.initial(initial))
            
        } catch {
            continuation.finish()
            return
        }
        
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in
                self?.frc.delegate = nil
                self?.delegateBridge = nil
            }
        }
    }
}
