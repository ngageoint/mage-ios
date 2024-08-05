//
//  UserRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import CLLocationCoordinate2DExtensions

private struct UserRepositoryProviderKey: InjectionKey {
    static var currentValue: UserRepository = UserRepository()
}

extension InjectedValues {
    var userRepository: UserRepository {
        get { Self[UserRepositoryProviderKey.self] }
        set { Self[UserRepositoryProviderKey.self] = newValue }
    }
}

struct UserModel: Equatable, Hashable {
    var userId: URL?
    var remoteId: String?
    var name: String?
    var coordinate: CLLocationCoordinate2D?
    var email: String?
    var phone: String?
    var lastUpdated: Date?
    var avatarUrl: String?
    var username: String?
    var timestamp: Date?
    var hasEditPermissions: Bool = false
    
    init(user: User) {
        remoteId = user.remoteId
        name = user.name
        coordinate = user.coordinate
        email = user.email
        phone = user.phone
        lastUpdated = user.lastUpdated
        avatarUrl = user.avatarUrl
        username = user.username
        timestamp = user.location?.timestamp
        userId = user.objectID.uriRepresentation()
        hasEditPermissions = user.hasEditPermission
    }
}

class UserRepository: ObservableObject {
    @Injected(\.userLocalDataSource)
    var localDataSource: UserLocalDataSource

    func getUser(userUri: URL?) async -> User? {
        await localDataSource.getUser(userUri: userUri)
    }
    
    func getCurrentUser() -> User? {
        localDataSource.getCurrentUser()
    }
    
    func observeUser(userUri: URL?) -> AnyPublisher<UserModel, Never>? {
        localDataSource.observeUser(userUri: userUri)
    }
    
    func getUser(remoteId: String) -> User? {
        localDataSource.getUser(remoteId: remoteId)
    }
}
