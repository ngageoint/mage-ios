import LayerFetch
import ServerDTO
import FetchOperation
import Pipeline

public final class StaticLayerDataFetchUseCase: Sendable {
    let repository: AnyFetchRepository<StaticLayerDataFetchRequest, StaticLayerRepositoryFetchResult>
    
    init(
        repository: AnyFetchRepository<StaticLayerDataFetchRequest, StaticLayerRepositoryFetchResult>
    ) {
        self.repository = repository
    }
    
    func execute(eventID: EventID?, layerID: LayerID?) async throws {
        guard let eventID,
              let layerID
        else {
            return
        }
                
        let operation = repository.startFetch(
            StaticLayerDataFetchRequest(eventID: eventID, layerID: layerID)
        )
        _ = try await operation.value()
        
        LayerFetchPackage.logger.info("Fetched static layer data for layer \(layerID.rawValue)")
    }
}
