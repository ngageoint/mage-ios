import Foundation
import Persistence
import FetchOperation
import ServerDTO
import APIRouter
import Pipeline

public struct LayerFetchRequest: Sendable {
    public let eventID: EventID
    
    public init(
        eventID: EventID
    ) {
        self.eventID = eventID
    }
}

public struct StaticLayerDataFetchRequest: Sendable {
    public let eventID: EventID
    public let layerID: LayerID
    
    public init(
        eventID: EventID,
        layerID: LayerID
    ) {
        self.eventID = eventID
        self.layerID = layerID
    }
}

public class LayerFetchRepositoryFactory {
    public static let LayerDataFetchOperationKind = PipelineOperationKind(rawValue: "fetch layers")
    
    public static func fetchLayers(
        url: URL,
        session: TokenAPISession,
        persistence: PersistenceProtocol
    ) -> AnyFetchRepository<LayerFetchRequest, [MapLayerDTO]> {
        AnyFetchRepository(
            FetchRepository<LayerFetchRequest, [MapLayerDTO]> { input in
                let request = LayerFetchRouter(
                    baseURL: url,
                    endpoint:
                            .fetchLayers(
                                eventID: input.eventID
                            )
                )
                
                let remote = LayerFetchRemoteImpl(
                    url: url,
                    session: session
                )
                let layerImporter = LayerImporterImpl(persistence: persistence)
                
                var context = LayerPipelineContext(eventID: input.eventID)
                context.urlRequest = try? request.asURLRequest()
                
                let pipeline = Pipeline(
                    operation: LayerDataFetchOperationKind,
                    context: context
                ) {
                    PipelineStep<LayerPipelineContext>.download(remote: remote)
                    PipelineStep<LayerPipelineContext>.saveLayers(layerImporter: layerImporter)
                } output: {
                    return $0.dto
                }
                return pipeline.execute()
            }
        )
    }
    
    public static func staticLayerData(
        url: URL,
        session: TokenAPISession,
        persistence: PersistenceProtocol
    ) -> AnyFetchRepository<StaticLayerDataFetchRequest, StaticLayerRepositoryFetchResult> {
        AnyFetchRepository(
            FetchRepository<StaticLayerDataFetchRequest, StaticLayerRepositoryFetchResult> { input in
                let local = StaticLayerFetchLocalImpl(
                    persistence: persistence
                )
                
                let request = LayerFetchRouter(
                    baseURL: url,
                    endpoint:
                            .fetchStaticLayerData(
                                eventID: input.eventID,
                                layerID: input.layerID
                            )
                )
                let remote = StaticLayerFetchRemoteImpl(
                    url: url,
                    session: session
                )
                
                let iconFetcher = StaticLayerIconFetchImpl()
                
                var context = StaticLayerPipelineContext(eventID: input.eventID, layerID: input.layerID)
                context.urlRequest = try? request.asURLRequest()
                
                let pipeline = Pipeline(
                    operation: LayerDataFetchOperationKind,
                    context: context
                ) {
                    PipelineStep<StaticLayerPipelineContext>.downloadStaticLayerData(remote: remote)
                    PipelineStep<StaticLayerPipelineContext>.saveStaticLayerData(local: local)
                    PipelineStep<StaticLayerPipelineContext>.saveStaticLayerIcons(fetcher: iconFetcher)
                } output: {
                    return StaticLayerRepositoryFetchResult(
                        dto: $0.staticLayerFeatureCollectionDTO
                    )
                }
                
                return pipeline.execute()
            }
        )
    }
}
