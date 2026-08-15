//
//  File.swift
//  User
//
//  Created by Daniel Barela on 8/6/26.
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
