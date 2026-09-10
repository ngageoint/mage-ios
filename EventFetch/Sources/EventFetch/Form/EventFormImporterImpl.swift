import ServerDTO
import FetchOperation
import Persistence
import Form
import CoreData
import Pipeline

public final class EventFormImporterImpl: EventFormImporter {
    public typealias DTO = EventFormDTO
    public typealias SaveResult = DefaultSaveResult
    
    let persistence: PersistenceProtocol
    
    public init(
        persistence: PersistenceProtocol
    ) {
        self.persistence = persistence
    }
    
    public func deleteForms(eventID: EventID) async throws -> SaveResult {
        let persistenceResult = try await persistence.write { context in
            context
                .deleteAll(
                    Form.self,
                    matching: NSPredicate(
                        format: "eventId == %@",
                        eventID.rawValue
                    )
                )
        }
        var deleteResult = DefaultSaveResult.empty
        deleteResult.deleted = persistenceResult.blockReturn ?? 0
        
        return deleteResult
    }
    
    public func saveForms(
        _ dto: [DTO],
        eventID: EventID,
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult {
        let persistenceResult = try await persistence.write { context in
            var saveResult = DefaultSaveResult.empty
            for (index, formDTO) in dto.enumerated() {
                let form = Form(
                    formDTO: formDTO,
                    eventId: eventID,
                    index: index,
                    writeContext: context
                )
                try? context.obtainPermanentIDs(for: [form])
                
                if saveResult.totalChanged % 5 == 0 {
                    try Task.checkCancellation()
                    progress(
                        OperationProgress(
                            completed: Int64(saveResult.totalChanged),
                            total: Int64(dto.count)
                        )
                    )
                }
                saveResult.combine(with: .insert)
            }
            progress(
                OperationProgress(
                    completed: Int64(saveResult.totalChanged),
                    total: Int64(dto.count)
                )
            )
            return saveResult
        }
        return persistenceResult.blockReturn ?? .empty
    }
}
