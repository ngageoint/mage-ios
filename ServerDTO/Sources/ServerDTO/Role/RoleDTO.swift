//
//  RoleDTO.swift
//  MAGE
//
//


import Foundation

// periphery:ignore - DTO is meant to reflect the server
public struct RoleDTO: Codable, Sendable {
    public init(id: String? = nil, name: String? = nil, description: String? = nil, permissions: [String]? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.permissions = permissions
    }
    
    public let id: String?
    public let name: String?
    public let description: String?
    public let permissions: [String]?
}
