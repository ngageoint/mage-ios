//
//  GetUserUseCase.swift
//  User
//
//

import ServerDTO

public final class GetUserUseCase: Sendable {

    private let repository: UserRepository

    public init(
        repository: UserRepository
    ) {
        self.repository = repository
    }

    public func execute(
        userID: UserID
    ) async throws -> UserModel? {
        if let cached = try await repository.getUser(
            userID: userID
        ) {
            return cached
        }

        return try await repository.refreshUser(
            userID: userID
        )
    }
}
