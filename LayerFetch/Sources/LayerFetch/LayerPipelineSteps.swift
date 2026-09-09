import FetchOperation
import ServerDTO
import Foundation
import Layer
import Pipeline

public extension PipelineStep where Context: EventToLayerContext & LayerSaveResultContext {
    static func saveLayers(
        layerImporter: LayerImporter
    ) -> Self {
        Self(
            phase: .saving,
            perform: { context, progress in
                
                var context = context
                
                var saveResult = LayerSaveResult.empty
                for eventToLayerDTO in context.eventToLayerDTO {
                    let saveLayersResult = try await layerImporter.synchronizeLayers(
                        eventToLayerDTO.layerDTO,
                        eventID: eventToLayerDTO.eventID,
                        progress: progress
                    )
                    saveResult.combine(with: saveLayersResult)
                }
                
                context.layerSaveResult = saveResult
                
                return context
            }
        )
    }
}

public extension PipelineStep where Context: DTOContext & LayerSaveResultContext & EventIDContext {
    static func saveLayers(
        layerImporter: LayerImporter
    ) -> Self where Context.DTO == MapLayerDTO {
        Self(
            phase: .saving,
            perform: { context, progress in
                
                var context = context
                
                var saveResult = LayerSaveResult.empty
                let saveLayersResult = try await layerImporter.synchronizeLayers(
                    context.dto,
                    eventID: context.eventID,
                    progress: progress
                )
                saveResult.combine(with: saveLayersResult)
                
                context.layerSaveResult = saveResult
                
                return context
            }
        )
    }
}

public extension PipelineStep where Context: StaticLayerFeatureCollectionDTOContext & URLRequestContext {
    static func downloadStaticLayerData(
        remote: any StaticLayerFetchRemote
    ) -> Self
    {
        
        Self(
            phase: .downloading
        ) { context, progress in
            
            var context = context
            
            context.staticLayerFeatureCollectionDTO = try await remote.fetch(
                urlRequest: context.urlRequest,
                progress: progress
            ).first
            
            return context
        }
    }
}

public extension PipelineStep where Context: StaticLayerFeatureCollectionDTOContext & EventIDContext & LayerIDContext & StaticLayerSaveResultContext {
    static func saveStaticLayerData(
        local: any StaticLayerFetchLocal
    ) -> Self
    {
        
        Self(
            phase: .downloading
        ) { context, progress in
            
            var context = context
            guard let dto = context.staticLayerFeatureCollectionDTO else {
                return context
            }
            context.staticLayerSaveResult = try await local.save(
                    dto,
                    eventID: context.eventID,
                    layerID: context.layerID,
                    progress: progress
                )
            
            return context
        }
    }
}

public extension PipelineStep where Context: StaticLayerSaveResultContext {
    static func saveStaticLayerIcons(
        fetcher: any StaticLayerIconFetch
    ) -> Self
    {
        
        Self(
            phase: .downloading
        ) { context, progress in
            
            let context = context
            guard let iconsToFetch = context.staticLayerSaveResult?.iconsToFetch else {
                return context
            }
            try await fetcher.fetch(iconsToFetch: iconsToFetch, progress: progress)
            return context
        }
    }
}

