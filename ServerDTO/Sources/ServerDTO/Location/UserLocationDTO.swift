//
//  UserLocationDTO.swift
//  ServerDTO
//
//


import Foundation

// periphery:ignore - DTO is meant to reflect the server
public struct UserLocationDTO: Decodable, Sendable {
    public init(id: String? = nil, user: UserDTO? = nil, locations: [LocationDTO]? = nil) {
        self.id = id
        self.user = user
        self.locations = locations
    }
    
    public let id: String?
    public let user: UserDTO?
    public let locations: [LocationDTO]?
}
