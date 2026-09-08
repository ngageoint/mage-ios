import FetchOperation
import ServerDTO
import Foundation

public protocol EventToLayerContext: Sendable {
    var eventToLayerDTO: [EventToLayerDTO] { get set }
}

public protocol LayerSaveResultContext: Sendable {
    var layerSaveResult: LayerSaveResult? { get set }
}

public protocol StaticLayerFeatureCollectionDTOContext: Sendable {
    var staticLayerFeatureCollectionDTO: StaticLayerFeatureCollectionDTO? { get set }
}

public protocol StaticLayerSaveResultContext: Sendable {
    var staticLayerSaveResult: StaticLayerSaveResult? { get set }
}

public protocol EventIDContext: Sendable {
    var eventID: EventID { get }
}

public protocol LayerIDContext: Sendable {
    var layerID: LayerID { get }
}

public struct StaticLayerPipelineContext: StaticLayerFeatureCollectionDTOContext, StaticLayerSaveResultContext, URLRequestContext, EventIDContext, LayerIDContext {
    public init(eventID: EventID, layerID: LayerID) {
        self.eventID = eventID
        self.layerID = layerID
    }
    public var staticLayerSaveResult: StaticLayerSaveResult?
    
    public let eventID: EventID
    public let layerID: LayerID
    public var staticLayerFeatureCollectionDTO: StaticLayerFeatureCollectionDTO?
    public var urlRequest: URLRequest?
}

public struct LayerPipelineContext: DTOContext, LayerSaveResultContext, URLRequestContext, EventIDContext {
    public var dto: [MapLayerDTO] = []

    public typealias DTO = MapLayerDTO

    public init(eventID: EventID) {
        self.eventID = eventID
    }
    public var layerSaveResult: LayerSaveResult?
    
    public let eventID: EventID
    public var urlRequest: URLRequest?
}

import ServerDTO

public struct StaticLayerRepositoryFetchResult: Sendable {
    public init(
        dto: StaticLayerFeatureCollectionDTO?,
    ) {
        self.dto = dto
    }
    
    public let dto: StaticLayerFeatureCollectionDTO?
}

import ServerDTO

public struct LayerRepositoryFetchResult: Sendable {
    public init(
        dto: [MapLayerDTO],
    ) {
        self.dto = dto
    }
    
    public let dto: [MapLayerDTO]
}
