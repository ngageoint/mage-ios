import ServerDTO
import FetchOperation
import LayerFetch

public struct EventRepositoryFetchResult: Sendable {
    public init(
        dto: [EventDTO],
        eventSaveResult: EventSaveResult? = nil,
        layerSaveResult: LayerSaveResult? = nil,
        formSaveResult: DefaultSaveResult? = nil,
        teamSaveResult: TeamSaveResult? = nil
    ) {
        self.dto = dto
        self.eventSaveResult = eventSaveResult
        self.layerSaveResult = layerSaveResult
        self.formSaveResult = formSaveResult
        self.teamSaveResult = teamSaveResult
    }
    
    public let dto: [EventDTO]
    public let eventSaveResult: EventSaveResult?
    public let layerSaveResult: LayerSaveResult?
    public let formSaveResult: DefaultSaveResult?
    public let teamSaveResult: TeamSaveResult?
}
