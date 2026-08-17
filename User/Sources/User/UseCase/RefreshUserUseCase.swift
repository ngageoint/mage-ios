// 
//     
//  RefreshUserUseCase.swift
//  User
//
// 


import ServerDTO

public final class RefreshUserUseCase: Sendable {
    
    private let repository: UserRepository
    
    public init(
        repository: UserRepository
    ) {
        self.repository = repository
    }
    
    public func execute(
        userID: UserID
    ) async throws -> UserModel? {
        return try await repository.refreshUser(
            userID: userID
        )
    }
}
