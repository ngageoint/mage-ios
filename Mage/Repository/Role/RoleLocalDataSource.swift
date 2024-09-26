//
//  RoleLocalDataSource.swift
//  MAGETests
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct RoleLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: RoleLocalDataSource = RoleCoreDataDataSource()
}

extension InjectedValues {
    var roleLocalDataSource: RoleLocalDataSource {
        get { Self[RoleLocalDataSourceProviderKey.self] }
        set { Self[RoleLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol RoleLocalDataSource {
    func getRole(remoteId: String) -> RoleModel?
    func addUserToRole(roleJson: [AnyHashable : Any], user: User, context: NSManagedObjectContext)
}

class RoleCoreDataDataSource: CoreDataDataSource<Role>, RoleLocalDataSource, ObservableObject {
    func getRole(remoteId: String) -> RoleModel? {
        guard let context = context else { return nil }
        return context.fetchFirst(Role.self, key: "remoteId", value: remoteId).map { role in
            RoleModel(role: role)
        }
    }
    
    func addUserToRole(roleJson: [AnyHashable : Any], user: User, context: NSManagedObjectContext) {
        if let roleId = roleJson[RoleKey.id.key] as? String, let role = context.fetchFirst(Role.self, key: RoleKey.remoteId.key, value: roleId) {
            user.role = role
            role.addToUsers(user)
        } else {
            let role = Role.insert(json: roleJson, context: context)
            user.role = role
            role.addToUsers(user)
            try? context.obtainPermanentIDs(for: [role])
        }
    }
}
