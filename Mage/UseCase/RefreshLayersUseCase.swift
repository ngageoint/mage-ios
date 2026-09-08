import UseCaseFactory
import ServerDTO
import LayerFetch
import FetchOperation

public final class RefreshLayersUseCase: Sendable, UseCase {
    let repository: AnyFetchRepository<LayerFetchRequest, [MapLayerDTO]>
    
    init(repository: AnyFetchRepository<LayerFetchRequest, [MapLayerDTO]>) {
        self.repository = repository
    }
    
    func execute(eventID: EventID) async throws {
        let operation = repository.startFetch(LayerFetchRequest(eventID: eventID))
        
        let dto = try await operation.value()
        
        let eventIDString = eventID.rawValue.stringValue
        let layerRemoteIds = dto.map { dto in
            dto.remoteId.rawValue
        }
        var selectedOnlineLayers = UserDefaults.standard.selectedOnlineLayers ?? [:]
        
        // get the currently selected online layers, remove all existing layers and then delete the ones that are left
        var removedSelectedOnlineLayers: [NSNumber] = selectedOnlineLayers[eventIDString] ?? [];
        removedSelectedOnlineLayers.removeAll { layerRemoteId in
            layerRemoteIds.contains(layerRemoteId)
        }
        
        var selectedEventOnlineLayers = selectedOnlineLayers[eventIDString] ?? [];
        selectedEventOnlineLayers.removeAll { layerRemoteId in
            removedSelectedOnlineLayers.contains(layerRemoteId)
        }
        
        selectedOnlineLayers[eventIDString] = selectedEventOnlineLayers;
        UserDefaults.standard.selectedOnlineLayers = selectedOnlineLayers;
        
        var selectedStaticLayers = UserDefaults.standard.selectedStaticLayers ?? [:]
        
        // get the currently selected online layers, remove all existing layers and then delete the ones that are left
        var removedSelectedStaticLayers: [NSNumber] = selectedStaticLayers[eventIDString] ?? [];
        removedSelectedStaticLayers.removeAll { layerRemoteId in
            layerRemoteIds.contains(layerRemoteId)
        }
        
        var selectedEventStaticLayers = selectedStaticLayers[eventIDString] ?? [];
        selectedEventStaticLayers.removeAll { layerRemoteId in
            removedSelectedStaticLayers.contains(layerRemoteId)
        }
        
        selectedStaticLayers[eventIDString] = selectedEventStaticLayers;
        UserDefaults.standard.selectedStaticLayers = selectedStaticLayers;
    }
}
