//
//  UserLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 6/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct UserLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: UserLocalDataSource = UserCoreDataDataSource()
}

extension InjectedValues {
    var userLocalDataSource: UserLocalDataSource {
        get { Self[UserLocalDataSourceProviderKey.self] }
        set { Self[UserLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol UserLocalDataSource {
    func getUser(userUri: URL?) async -> User?
    func getCurrentUser() -> User?
    func observeUser(
        userUri: URL?
    ) -> AnyPublisher<UserModel, Never>?
    
    func getUser(remoteId: String) async -> User?
}

class UserCoreDataDataSource: CoreDataDataSource, UserLocalDataSource, ObservableObject {
    func getUser(userUri: URL?) async -> User? {
        guard let userUri = userUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: userUri) {
                return try? context.existingObject(with: id) as? User
            }
            return nil
        }
    }
    
    func getCurrentUser() -> User? {
        User.fetchCurrentUser(context: NSManagedObjectContext.mr_default())
    }
    
    func getUser(remoteId: String) async -> User? {
        let context = NSManagedObjectContext.mr_default()
        return await context.perform {
            return context.fetchFirst(User.self, key: "remoteId", value: remoteId)
        }
    }
    
    func observeUser(userUri: URL?) -> AnyPublisher<UserModel, Never>? {
        guard let userUri = userUri else {
            return nil
        }
        let context = NSManagedObjectContext.mr_default()
        return context.performAndWait {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: userUri) {
                if let user = try? context.existingObject(with: id) as? User {
                    return publisher(for: user, in: context)
                        .prepend(user)
                        .map({ user in
                            return UserModel(user: user)
                        })
                        .eraseToAnyPublisher()
                }
            }
            return nil
        }
    }
}
