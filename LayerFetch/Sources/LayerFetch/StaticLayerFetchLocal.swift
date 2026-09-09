import ServerDTO
import FetchOperation
import Pipeline

public protocol StaticLayerFetchLocal: Sendable where DTO == StaticLayerFeatureCollectionDTO, SaveResult == StaticLayerSaveResult {
    
    associatedtype DTO: Sendable
    associatedtype SaveResult: Sendable
    
    @discardableResult
    func save(
        _ dto: DTO,
        eventID: EventID,
        layerID: LayerID,
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult
}
