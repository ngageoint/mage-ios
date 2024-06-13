//
//  UserRepository.swift
//  MAGE
//
//  Created by Dan Barela on 6/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct UserRepositoryProviderKey: InjectionKey {
    static var currentValue: UserRepository = UserRepository()
}

extension InjectedValues {
    var userRepository: UserRepository {
        get { Self[UserRepositoryProviderKey.self] }
        set { Self[UserRepositoryProviderKey.self] = newValue }
    }
}

class UserRepository: ObservableObject {
    @Injected(\.userLocalDataSource)
    var localDataSource: UserLocalDataSource

    func getUser(userUri: URL?) async -> User? {
        await localDataSource.getUser(userUri: userUri)
    }
}
