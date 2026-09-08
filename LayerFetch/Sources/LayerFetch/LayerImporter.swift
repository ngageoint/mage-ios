import ServerDTO
import FetchOperation
import Pipeline

public protocol LayerImporter: Sendable {
    typealias DTO = MapLayerDTO
    typealias SaveResult = LayerSaveResult
    func synchronizeLayers(
        _ dto: [DTO],
        eventID: EventID,
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult
}
