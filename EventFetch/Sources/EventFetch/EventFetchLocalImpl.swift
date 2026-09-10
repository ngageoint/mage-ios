import Foundation
import Persistence
import FetchOperation
import ServerDTO
import CodableExtensions
import Event
import Pipeline

public final class EventFetchLocalImpl: EventFetchLocal {
    public typealias DTO = EventDTO
    public typealias SaveResult = EventSaveResult
    
    let persistence: PersistenceProtocol
    
    public init(
        persistence: PersistenceProtocol
    ) {
        self.persistence = persistence
    }
    
    public func save(
        _ dto: [EventDTO],
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult {
        
        let persistenceResult = try await persistence.write { context in
            var eventsReturned: [NSNumber] = []
            
            var saveResult = EventSaveResult.empty
            let totalCount = Int64(dto.count)
            for eventDTO in dto {
                let event: Event = try {
                    if let event = context.fetchFirst(
                        Event.self,
                        key: EventKey.remoteId.key,
                        value: eventDTO.id.rawValue
                    ) {
                        saveResult.combine(with: .update)
                        return event
                    } else {
                        let event = Event(context: context)
                        try context.obtainPermanentIDs(for: [event])
                        saveResult.combine(with: .insert)
                        return event
                    }
                }()
                event.apply(dto: eventDTO)
                if let remoteId = event.remoteId {
                    eventsReturned.append(remoteId)
                }
                
                if saveResult.totalChanged % 50 == 0 {
                    try Task.checkCancellation()
                    progress(
                        OperationProgress(
                            completed: Int64(saveResult.totalChanged),
                            total: totalCount
                        )
                    )
                }
            }

            let deleted = context.deleteAll(Event.self, matching: NSPredicate(format: "NOT (\(EventKey.remoteId.key) IN %@)", eventsReturned))
            saveResult.deleted += deleted
            EventFetchPackage.logger.info("\(saveResult)")
            
            progress(
                OperationProgress(
                    completed: Int64(saveResult.totalChanged),
                    total: totalCount
                )
            )
            
            return saveResult
        }
        
        return persistenceResult.blockReturn ?? .empty
    }
}

public extension Event {
    func apply(
        dto: EventDTO
    ) {
        self.remoteId = dto.id.rawValue
        self.name = dto.name
        if let intMaxObservationForms = dto.maxObservationForms {
            self.maxObservationForms = NSNumber(value: intMaxObservationForms)
        }
        if let intMinObservationForms = dto.minObservationForms {
            self.minObservationForms = NSNumber(value: intMinObservationForms)
        }
        self.eventDescription = dto.description
        let jsonAcl = dto.acl?.mapValues { $0.dictionary }.compactMapValues { $0 }
        self.acl = jsonAcl
    }
}
