//
//  UserRemote.swift
//  User
//

import ServerDTO
import Foundation
import APIRouter

public protocol UserRemote: Sendable {
    func fetchMyself() async throws -> UserDTO
    func fetch(userID: UserID) async throws -> UserDTO
}

public final class UserRemoteImpl: UserRemote {
    let url: URL
    let session: TokenAPISession
    
    public init(
        url: URL,
        session: TokenAPISession
    ) {
        self.url = url
        self.session = session
    }
    
    public func fetchMyself() async throws -> UserDTO {
        
        let request = UserRouter(
            baseURL: url,
            endpoint: .fetchMyself
        )
        
        return try await session.session
            .request(request)
            .validate(session.validateResponse())
            .serializingDecodable(UserDTO.self)
            .value
    }
    
    public func fetch(userID: UserID) async throws -> UserDTO {
        let request = UserRouter(
            baseURL: url,
            endpoint: .fetchUser(remoteId: userID)
        )
        
        return try await session.session
            .request(request)
            .validate(session.validateResponse())
            .serializingDecodable(UserDTO.self)
            .value
    }
}
