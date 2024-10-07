//
//  RoleModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct RoleModel: Equatable, Hashable {
    var permissions: [String]?
    var remoteId: String?
    var users: Set<UserModel>?
}

extension RoleModel {
    init(role: Role) {
        permissions = role.permissions
        remoteId = role.remoteId
        users = role.users?.setmap(transform: { user in
            UserModel(user: user)
        })
    }
}
