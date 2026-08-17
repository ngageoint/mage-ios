//
//  RoleModel.swift
//  User
//
//

import Persistence

public struct RoleModel: Equatable, Hashable, Sendable {
    public init(permissions: [String]? = nil, remoteId: String? = nil) {
        self.permissions = permissions
        self.remoteId = remoteId
    }
    
    public var permissions: [String]?
    public var remoteId: String?
}

extension RoleModel: CoreDataDomainModelConvertible {
    public init(from role: Role) {
        self.init(permissions: role.permissions, remoteId: role.remoteId)
    }
}
