//
//  UserRepositoryFactory.swift
//  User
//
//

import Foundation
import APIRouter
import Persistence

public class UserRepositoryFactory {
    public static func createUserRepository(
        url: URL,
        session: TokenAPISession,
        persistence: PersistenceProtocol
    ) -> UserRepository {
        return UserRepositoryImpl(
            remote: UserRemoteImpl(
                url: url,
                session: session
            ),
            persistence: persistence,
            userImporter: UserImporterImpl()
        )
    }
}
