//
//  GetMyselfUseCase.swift
//  User
//
//  Created by Daniel Barela on 8/6/26.
//


import ServerDTO
import UseCaseFactory

public final class GetMyselfUseCase: Sendable, UseCase {
    
    private let repository: UserRepository
    
    public init(
        repository: UserRepository
    ) {
        self.repository = repository
    }
    
    public func execute() async throws -> UserModel? {
        
        return try await repository.fetchMyself()
    }
}
