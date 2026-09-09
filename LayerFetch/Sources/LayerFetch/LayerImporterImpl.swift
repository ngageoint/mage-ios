import ServerDTO
import Persistence
import FetchOperation
import CoreData
import Layer
import Pipeline

public final class LayerImporterImpl: LayerImporter {
    public typealias DTO = MapLayerDTO
    public typealias SaveResult = LayerSaveResult
    
    let persistence: PersistenceProtocol
    
    public init(
        persistence: PersistenceProtocol
    ) {
        self.persistence = persistence
    }
    
    private func fetchOrCreate<T: NSManagedObject>(
        _ type: T.Type,
        predicate: NSPredicate,
        context: NSManagedObjectContext,
        saveResult: inout LayerSaveResult,
        configureNew: (T) throws -> Void = { _ in }
    ) throws -> T {
        if let object = try context.fetchFirst(type, predicate: predicate) {
            saveResult.updated += 1
            return object
        }
        
        let object = T(context: context)
        try configureNew(object)
        try context.obtainPermanentIDs(for: [object])
        saveResult.inserted += 1
        return object
    }
    
    public func synchronizeLayers(
        _ dto: [DTO],
        eventID: EventID,
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult {

        let persistenceResult = try await persistence.write { context in
            var layerRemoteIds: Set<NSNumber> = []
            var saveResult = LayerSaveResult.empty
            let total = Int64(dto.count)
            
            func reportProgress() {
                progress(
                    OperationProgress(
                        completed: Int64(saveResult.totalChanged),
                        total: total
                    )
                )
            }
            
            for layerDTO in dto {
                let remoteLayerId = layerDTO.remoteId
                layerRemoteIds.insert(remoteLayerId.rawValue)
                let existingLayerPredicate = self.layerPredicate(
                    remoteID: remoteLayerId.rawValue.int64Value,
                    eventID: eventID
                )
                switch LayerType(rawValue: layerDTO.type ?? "") {
                case .Feature:
                    let layer = try self.fetchOrCreate(
                        StaticLayer.self,
                        predicate: existingLayerPredicate,
                        context: context,
                        saveResult: &saveResult
                    ) {
                        $0.initializeDownloadState()
                    }
                    
                    layer.apply(dto: layerDTO, eventID: eventID)
                    
                case .GeoPackage:
                    let layer = try self.fetchOrCreate(
                        Layer.self,
                        predicate: existingLayerPredicate,
                        context: context,
                        saveResult: &saveResult
                    ) {
                        $0.initializeDownloadState()
                    }
                    layer.apply(dto: layerDTO, eventID: eventID)
                    try self.preserveDownloadState(
                        for: layer,
                        remoteID: remoteLayerId.rawValue.int64Value,
                        eventID: eventID,
                        context: context
                    )
                    
                case .Imagery:
                    let layer = try self.fetchOrCreate(
                        ImageryLayer.self,
                        predicate: existingLayerPredicate,
                        context: context,
                        saveResult: &saveResult
                    )
                    
                    layer.applyImageryLayer(dto: layerDTO, eventID: eventID)
                    
                default:
                    let layer = try self.fetchOrCreate(
                        Layer.self,
                        predicate: existingLayerPredicate,
                        context: context,
                        saveResult: &saveResult
                    ) {
                        $0.initializeDownloadState()
                    }
                    layer.apply(dto: layerDTO, eventID: eventID)
                }
                
                if saveResult.totalChanged % 5 == 0 {
                    try Task.checkCancellation()
                    reportProgress()
                }
            }
            
            let layersNotReturned = try context.fetchObjects(
                Layer.self,
                predicate: NSPredicate(
                    format: "(NOT (\(LayerKey.remoteId.key) IN %@)) AND \(LayerKey.eventId.key) == %@",
                    layerRemoteIds,
                    eventID.rawValue
                )
            )
    
            for layer in layersNotReturned ?? [] {
                context.delete(layer)
            }
            saveResult.deleted = layersNotReturned?.count ?? 0
            
            reportProgress()
            
            return saveResult
        }
        return persistenceResult.blockReturn ?? .empty
    }
    

    
    private func preserveDownloadState(
        for layer: Layer,
        remoteID: Int64,
        eventID: EventID,
        context: NSManagedObjectContext
    ) throws {
        // If this layer already exists but for a different event, set it's downloaded status
        if let existing = try context.fetchFirst(
            Layer.self,
            predicate: NSPredicate(
                format: "\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) != %@",
                NSNumber(value: remoteID),
                eventID.rawValue
            )
        ) {
            // Preserve download status across events because the GeoPackage
            // is shared by remote ID regardless of event.
            layer.loaded = existing.loaded
        }
    }
    
    private func layerPredicate(
        remoteID: Int64,
        eventID: EventID
    ) -> NSPredicate {
        NSPredicate(
            format: "(\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) == %@)",
            NSNumber(value: remoteID),
            eventID.rawValue
        )
    }
}
