//
//  UserLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 6/12/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

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
}
