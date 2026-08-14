//
//  UserImporterImpl.swift
//  MAGE
//
//  Created by Daniel Barela on 8/4/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//

import CoreData
import ServerDTO
import Persistence

public final class UserImporterImpl: UserImporter, Sendable {
    public init() {
        
    }
    
    public func importUser(
        _ dto: UserDTO,
        context: NSManagedObjectContext
    ) throws -> UserModel? {
        guard let userId = dto.id
        else {
            return nil
        }
        
        let user: User = try {
            if let user = context.fetchFirst(User.self, key: UserKey.remoteId.key, value: userId) {
                print("this one is old")
                return user
            } else {
                let user = User(context: context)
                try context.obtainPermanentIDs(for: [user])
                print("This one is new")
                return user
            }
        }()
        user.remoteId = userId
        user.username = dto.username
        user.email = dto.email
        user.name = dto.displayName
        print("Set the name to \(dto.displayName ?? "<nothing>")")
        if let phones = dto.phones, phones.count > 0 {
            user.phone = phones[0].number
        }
        user.iconUrl = dto.iconUrl
        if let icon = dto.icon {
            user.iconText = icon.text
            user.iconColor = icon.color
        }
        user.avatarUrl = dto.avatarUrl
        user.recentEventIds = dto.recentEventIds?.map({ int in
            NSNumber(value: int)
        })
        
        user.createdAt = dto.createdAt
        user.lastUpdated = dto.lastUpdated
        
        if let userRole = dto.role {
            if let roleId = userRole.id, let role = context.fetchFirst(Role.self, key: RoleKey.remoteId.key, value: roleId) {
                user.role = role
                role.addToUsers(user)
            } else {
                let role = Role(context: context);
                role.remoteId = userRole.id
                role.permissions = userRole.permissions
                
                user.role = role
                role.addToUsers(user)
                try context.obtainPermanentIDs(for: [role])
            }
        } else if let roleId = dto.roleId {
            if let role = context.fetchFirst(Role.self, key: RoleKey.remoteId.key, value: roleId) {
                user.role = role
                role.addToUsers(user)
            }
        }
                
        return UserModel(from: user)
    }
}
