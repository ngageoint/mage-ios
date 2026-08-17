//
//  UserRepository.swift
//  MAGE
//

import ServerDTO
import Persistence

public final class UserRepositoryImpl: UserRepository {
    private let remote: UserRemote
    private let persistence: PersistenceProtocol
    private let userImporter: UserImporter
    
    public init(
        remote: UserRemote,
        persistence: PersistenceProtocol,
        userImporter: UserImporter
    ) {
        self.remote = remote
        self.persistence = persistence
        self.userImporter = userImporter
    }
    
    public func fetchMyself() async throws -> UserModel? {
        let dto = try await remote.fetchMyself()
        let result = try await persistence.write { context in
            let userModel = try self.userImporter.importUser(
                dto,
                context: context
            )
            return userModel
        }
        return result.blockReturn
    }
    
    public func getUser(
        userID: UserID
    ) async throws -> UserModel? {
        await persistence.read { context in
            guard let user = context.fetchFirst(
                User.self,
                key: UserKey.remoteId.key,
                value: userID
            ) else {
                return nil
            }
            
            return UserModel(from: user)
        }
    }
    
    public func refreshUser(
        userID: UserID
    ) async throws -> UserModel? {
        
        let dto = try await remote.fetch(
            userID: userID
        )
        
        let result = try await persistence.write { context in
            let userModel = try self.userImporter.importUser(
                dto,
                context: context
            )
            return userModel
        }
        return result.blockReturn
    }
}
