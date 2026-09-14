import Foundation
import Persistence
import User
import CoreData
import SendableExtensions
import ServerDTO

public struct EventModel: Identifiable, Sendable {
    public init(name: String? = nil, remoteId: EventID? = nil, sendableAcl: [String : SendableValue]? = nil, teams: [TeamModel]? = nil, maxObservationForms: NSNumber? = nil, minObservationForms: NSNumber? = nil, eventDescription: String? = nil, unsyncedObservationCount: Int = 0) {
        self.name = name
        self.remoteId = remoteId
        self.sendableAcl = sendableAcl
        self.teams = teams
        self.maxObservationForms = maxObservationForms
        self.minObservationForms = minObservationForms
        self.eventDescription = eventDescription
        self.unsyncedObservationCount = unsyncedObservationCount
    }
    
    public var id: NSNumber { remoteId?.rawValue ?? -1 }
    
    public var name: String?
    public var remoteId: EventID?
    public var sendableAcl: [String: SendableValue]?
    public var acl: [String: Any]? {
        get {
            sendableAcl?.toAnyValues()
        }
        set {
            sendableAcl = newValue?.toSendableValues()
        }
    }
    public var teams: [TeamModel]?
    public var maxObservationForms: NSNumber?
    public var minObservationForms: NSNumber?
    public var eventDescription: String?
    public var unsyncedObservationCount: Int = 0
    
    public func isUserInEvent(user: UserModel) -> Bool {
        guard let teams else { return false }
        for team in teams {
            if let users = team.users {
                let inEvent = users.contains(where: { userModel in
                    userModel.remoteId == user.remoteId
                })
                if inEvent {
                    return true
                }
            }
        }
        return false
    }
}

extension EventModel: CoreDataDomainModelConvertible {
    public init(from event: Event) {
        remoteId = event.remoteId.map(EventID.init)
        acl = event.acl as? [String: Any]
        teams = event.teams?.map(TeamModel.init)
        maxObservationForms = event.maxObservationForms
        minObservationForms = event.minObservationForms
        name = event.name
        eventDescription = event.eventDescription
        unsyncedObservationCount = event.unsyncedObservations.count
        
    }
}
