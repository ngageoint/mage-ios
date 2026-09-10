import ServerDTO

public protocol EventDTOContext: Sendable {
    var eventDTO: [EventDTO] { get set }
}

public protocol EventSaveResultContext: Sendable {
    var eventSaveResult: EventSaveResult? { get set }
}
