import ServerDTO

public struct EventToLayerDTO: Sendable {
    public init(eventID: EventID, layerDTO: [MapLayerDTO]) {
        self.eventID = eventID
        self.layerDTO = layerDTO
    }
    
    public let eventID: EventID
    public let layerDTO: [MapLayerDTO]
}
