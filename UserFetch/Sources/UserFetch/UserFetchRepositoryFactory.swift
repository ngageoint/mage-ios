//
//  UserRepositoryFactory.swift
//  MAGE
//
//

import Foundation
import Persistence
import FetchOperation
import ServerDTO
import APIRouter
import Pipeline

public struct UserFetchRequest: Sendable {
    public let eventID: EventID
    
    public init(
        eventID: EventID
    ) {
        self.eventID = eventID
    }
}

public class UserFetchRepositoryFactory {
    public static let UserFetchOperationKind = PipelineOperationKind(rawValue: "fetch users")

    public static func createFetchRepository(
        url: URL,
        session: TokenAPISession,
        persistence: PersistenceProtocol
    ) -> AnyFetchRepository<UserFetchRequest, [UserDTO]> {
        AnyFetchRepository(
            FetchRepository<UserFetchRequest, [UserDTO]> { input in
                
                let pipeline = FetchPipelines.default(
                    remote: UserFetchRemote(
                        url: url,
                        session: session,
                        eventID: input.eventID
                    ),
                    local: UserFetchLocalImpl(
                        persistence: persistence
                    ),
                    operation: UserFetchOperationKind
                )
                
                return pipeline.execute()
            }
        )
    }
}

