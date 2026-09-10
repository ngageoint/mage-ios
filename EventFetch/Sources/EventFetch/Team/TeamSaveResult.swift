import FetchOperation
import ServerDTO

public struct TeamSaveResult: Sendable, Equatable {
    public var inserted: Int
    public var updated: Int
    public var deleted: Int
    
    public var users: [TeamID: [String]]
    
    public var totalChanged: Int {
        inserted + updated + deleted
    }
    
    public static let empty =
    TeamSaveResult(
        inserted: 0,
        updated: 0,
        deleted: 0,
        users: [:]
    )
    
    public mutating func combine(with other: TeamSaveResult) {
        self.inserted += other.inserted
        self.updated += other.updated
        self.deleted += other.deleted
        self.users.merge(other.users) { $1 }
    }
    
    public mutating func addUsers(teamID: TeamID, userIDs: [String]) {
        self.users[teamID] = userIDs
    }
}
