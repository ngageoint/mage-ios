import ServerDTO
import Persistence
import FetchOperation
import User
import Pipeline
import Event

public final class TeamFetchLocalImpl: TeamFetchLocal {
    public typealias DTO = EventTeamDTO
    public typealias SaveResult = TeamSaveResult
    
    let persistence: PersistenceProtocol
    
    public init(
        persistence: PersistenceProtocol
    ) {
        self.persistence = persistence
    }
    
    public func save(
        _ dto: [DTO],
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult {
        let persistenceResult = try await persistence.write { context in
            var saveResult = TeamSaveResult.empty
            for eventTeam in dto {
                guard let event = context.fetchFirst(
                    Event.self,
                    key: EventKey.remoteId.key,
                    value: eventTeam.eventID.intValue
                ) else {
                    continue
                }
                for teamDTO in eventTeam.teamDTO {
                    let team: Team = try {
                        if let team = event.teams?.first(where: { team in
                            return team.remoteId == teamDTO.id
                        }) {
                            saveResult.updated += 1
                            return team
                        } else if let team = context.fetchFirst(Team.self, key: TeamKey.remoteId.key, value: teamDTO.id) {
                            saveResult.updated += 1
                            return team
                        } else {
                            let team = Team(context: context)
                            try context.obtainPermanentIDs(for: [team])
                            saveResult.inserted += 1
                            return team
                        }
                    }()
                    
                    team.apply(dto: teamDTO)
                    event.addToTeams(team)
                    if let userIds = teamDTO.userIds, !userIds.isEmpty {
                        for userId in userIds {
                            let user: User = try {
                                if let user = context.fetchFirst(User.self, key: UserKey.remoteId.key, value: userId) {
                                    return user
                                } else {
                                    let user = User(context: context)
                                    user.remoteId = userId
                                    try context.obtainPermanentIDs(for: [user])
                                    return user
                                }
                            }()
                            team.addToUsers(user)
                        }
                    }
                    
                    if saveResult.totalChanged % 5 == 0 {
                        try Task.checkCancellation()
                        progress(
                            OperationProgress(
                                completed: Int64(saveResult.totalChanged),
                                total: Int64(dto.count)
                            )
                        )
                    }
                }
            }
            progress(
                OperationProgress(
                    completed: Int64(saveResult.totalChanged),
                    total: Int64(dto.count)
                )
            )
            
            return saveResult
        }
        return persistenceResult.blockReturn ?? .empty
    }
}
