import ServerDTO
import FetchOperation

public struct EventToEventFormDTO: Sendable {
    public init(eventID: EventID, eventFormDTO: [EventFormDTO]) {
        self.eventID = eventID
        self.eventFormDTO = eventFormDTO
    }
    
    public let eventID: EventID
    public let eventFormDTO: [EventFormDTO]
}

public protocol EventToEventFormDTOContext: Sendable {
    var eventToEventFormDTO: [EventToEventFormDTO] { get set }
}

public protocol EventFormSaveResultContext: Sendable {
    var eventFormSaveResult: DefaultSaveResult? { get set }
}
