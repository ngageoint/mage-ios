import Persistence
import FetchOperation
import ServerDTO
import CoreData
import Layer
import Pipeline
import CodableExtensions

final class StaticLayerFetchLocalImpl: StaticLayerFetchLocal {
    typealias DTO = StaticLayerFeatureCollectionDTO
    typealias SaveResult = StaticLayerSaveResult
    
    let persistence: PersistenceProtocol
    
    init(persistence: PersistenceProtocol) {
        self.persistence = persistence
    }
    
    func save(
        _ dto: DTO,
        eventID: EventID,
        layerID: LayerID,
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult {
        
        _ = try await persistence.write { context in
            let staticLayer = try? context.fetchFirst(
                StaticLayer.self,
                predicate: NSPredicate(
                    format: "\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) == %@",
                    layerID.rawValue,
                    eventID.rawValue
                )
            )
            staticLayer?.downloading = true
        }
        let persistenceResult = try await persistence.write { context in
            let totalCount = Int64(dto.features.count)
            var saveCount: Int = 0
            
            let staticLayer = try? context.fetchFirst(
                StaticLayer.self,
                predicate: NSPredicate(
                    format: "\(LayerKey.remoteId.key) == %@ AND \(LayerKey.eventId.key) == %@",
                    layerID.rawValue,
                    eventID.rawValue
                )
            )
            guard let staticLayer,
                  var dictionaryResponse = dto.dictionary
            else {
                return StaticLayerSaveResult(
                    saveCount: saveCount,
                    iconsToFetch: []
                )
            }
            var iconsToFetch: [StaticLayerIconLocation] = []
            if var features = dictionaryResponse[LayerKey.features.key] as? [[AnyHashable : Any]] {
                for i in features.indices {
                    var feature = features[i]
                    if var featureProperties = feature[StaticLayerKey.properties.key] as? [AnyHashable : Any],
                       var style = featureProperties[StaticLayerKey.style.key] as? [AnyHashable : Any],
                       var iconStyle = style[StaticLayerKey.iconStyle.key] as? [AnyHashable : Any],
                       var icon = iconStyle[StaticLayerKey.icon.key] as? [AnyHashable : Any],
                       let href = icon[StaticLayerKey.href.key] as? String,
                       href.hasPrefix("https"),
                       let iconUrl = URL(string: href),
                       let featureId = feature[StaticLayerKey.id.key] as? String
                    {
                        iconsToFetch
                            .append(
                                StaticLayerIconLocation(
                                    url: iconUrl,
                                    layerID: layerID,
                                    featureID: StaticLayerFeatureID(featureId)
                                )
                            )
                        let featureIconRelativePath = "featureIcons/\(layerID)/\(featureId)"
                        icon[StaticLayerKey.localPath.key] = featureIconRelativePath
                        iconStyle[StaticLayerKey.icon.key] = icon
                        style[StaticLayerKey.iconStyle.key] = iconStyle
                        featureProperties[StaticLayerKey.style.key] = style
                        feature[StaticLayerKey.properties.key] = featureProperties
                        features[i] = feature
                    }
                    
                    dictionaryResponse[LayerKey.features.key] = features;
                    
                    let cleanedDictionaryResponse = dictionaryResponse.compactMapValues { $0 }
                    staticLayer.data = cleanedDictionaryResponse
                    staticLayer.loaded = NSNumber(floatLiteral: Layer.OFFLINE_LAYER_LOADED)
                    staticLayer.downloading = false
                    saveCount += 1
                    
                    if saveCount % 50 == 0 {
                        try Task.checkCancellation()
                        progress(
                            OperationProgress(
                                completed: Int64(saveCount),
                                total: totalCount
                            )
                        )
                    }
                }
            }
            progress(
                OperationProgress(
                    completed: Int64(saveCount),
                    total: totalCount
                )
            )
            
            LayerFetchPackage.logger.info("Saved \(saveCount) static layers")
            
            return StaticLayerSaveResult(saveCount: saveCount, iconsToFetch: iconsToFetch)
        }
        
        return persistenceResult.blockReturn ?? StaticLayerSaveResult(
            saveCount: 0,
            iconsToFetch: []
        )
    }
}
