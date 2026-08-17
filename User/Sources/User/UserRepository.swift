//
//  UserRepository.swift
//  User
//
//


import ServerDTO

public protocol UserRepository: Sendable {
    
    /// Always triggers a fetch to retrieve myself from the server and saves it
    /// - Returns: UserModel of myself
    func fetchMyself() async throws -> UserModel?
    
    /// Retrieves the user from the local storage
    /// - Returns: UserModel of the stored user
    func getUser(
        userID: UserID
    ) async throws -> UserModel?

    
    /// Always triggers a fetch to retrieve the user from the server and saves it
    /// - Returns: UserModel of the fetched user
    func refreshUser(
        userID: UserID
    ) async throws -> UserModel?
}
