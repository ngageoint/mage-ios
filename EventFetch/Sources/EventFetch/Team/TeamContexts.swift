import ServerDTO
import FetchOperation

public struct EventTeamDTO: Sendable, Decodable {
    public init(eventID: EventID, teamDTO: [TeamDTO]) {
        self.eventID = eventID
        self.teamDTO = teamDTO
    }
    
    public let eventID: EventID
    public let teamDTO: [TeamDTO]
}

public protocol TeamContext: Sendable {
    var teamDTO: [EventTeamDTO] { get set }
}

public protocol TeamSaveResultContext: Sendable {
    var teamSaveResult: TeamSaveResult? { get set }
}
