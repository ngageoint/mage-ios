import Foundation
import Persistence
import User
import ServerDTO

public struct TeamModel: Equatable, Hashable, Sendable {
    public init(teamId: URL? = nil, remoteId: TeamID? = nil, name: String? = nil, teamDescription: String? = nil, users: [UserModel]? = nil) {
        self.teamId = teamId
        self.remoteId = remoteId
        self.name = name
        self.teamDescription = teamDescription
        self.users = users
    }
    
    public var teamId: URL?
    public var remoteId: TeamID?
    public var name: String?
    public var teamDescription: String?
    public var users: [UserModel]?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(teamId)
        hasher.combine(remoteId)
        hasher.combine(name ?? "")
    }
    
    public static func == (lhs: TeamModel, rhs: TeamModel) -> Bool {
        return lhs.teamId == rhs.teamId && lhs.remoteId == rhs.remoteId && lhs.name == rhs.name
    }
}

extension TeamModel: CoreDataDomainModelConvertible {
    public init(from team: Team) {
        teamId = team.objectID.uriRepresentation()
        remoteId = team.remoteId.map(TeamID.init)
        name = team.name
        teamDescription = team.teamDescription
        users = team.users?.compactMap({ user in
            UserModel(from: user)
        })
    }
}
