import ServerDTO
import FetchOperation
import Pipeline

public protocol EventFormImporter: Sendable {
    typealias DTO = EventFormDTO
    typealias SaveResult = DefaultSaveResult
    
    func deleteForms(eventID: EventID) async throws -> SaveResult
    func saveForms(
        _ dto: [DTO],
        eventID: EventID,
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult
}
