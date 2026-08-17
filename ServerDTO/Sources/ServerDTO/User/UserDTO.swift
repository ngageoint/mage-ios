//
//  UserDTO.swift
//  MAGE
//
//


import Foundation

// periphery:ignore - DTO is meant to reflect the server
public struct UserDTO: Decodable, Sendable, Equatable {
    public init(
        id: String? = nil,
        username: String? = nil,
        email: String? = nil,
        displayName: String? = nil,
        phones: [UserPhoneDTO]? = nil,
        iconUrl: String? = nil,
        icon: UserIconDTO? = nil,
        avatarUrl: String? = nil,
        recentEventIds: [Int]? = nil,
        createdAt: Date? = nil,
        lastUpdated: Date? = nil,
        role: RoleDTO? = nil,
        roleId: String? = nil,
        enabled: Bool = true,
        active: Bool? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.phones = phones
        self.iconUrl = iconUrl
        self.icon = icon
        self.avatarUrl = avatarUrl
        self.recentEventIds = recentEventIds
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.role = role
        self.roleId = roleId
        self.enabled = enabled
        self.active = active
    }
    
    private enum Keys : String, CodingKey {
        case id
        case username
        case email
        case displayName
        case phones
        case number
        case iconUrl
        case icon
        case avatarUrl
        case recentEventIds
        case createdAt
        case lastUpdated
        case role
        case roleId
        case enabled
        case active
        
        var key: String {
            return self.rawValue
        }
    }
    
    public let id: String?
    public let username: String?
    public let email: String?
    public let displayName: String?
    public let phones: [UserPhoneDTO]?
    public let iconUrl: String?
    public let icon: UserIconDTO?
    public let avatarUrl: String?
    public let recentEventIds: [Int]?
    public let createdAt: Date?
    public let lastUpdated: Date?
    public let role: RoleDTO?
    public let roleId: String?
    public let enabled: Bool
    public let active: Bool?
    
    public func isEqualTo(_ other: UserDTO) -> Bool {
        return self.id == other.id
    }
    
    public static func == (lhs: UserDTO, rhs: UserDTO) -> Bool {
        lhs.isEqualTo(rhs)
    }
    
    static let dateFormatter: Date.ISO8601FormatStyle = {
        var style = Date.ISO8601FormatStyle.iso8601
            .year()
            .month()
            .day()
            .timeZone(separator: .omitted)
            .time(includingFractionalSeconds: true)
            .timeSeparator(.colon)
            .dateSeparator(.dash)
        style.timeZone = .gmt
        return style
    }()
    
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: Keys.self)
        self.id = try? values.decode(String.self, forKey: .id)
        self.username = try? values.decode(String.self, forKey: .username)
        self.email = try? values.decode(String.self, forKey: .email)
        self.displayName = try? values.decode(String.self, forKey: .displayName)
        self.phones = try? values.decode([UserPhoneDTO].self, forKey: .phones)
        self.iconUrl = try? values.decode(String.self, forKey: .iconUrl)
        self.icon = try? values.decode(UserIconDTO.self, forKey: .icon)
        self.avatarUrl = try? values.decode(String.self, forKey: .avatarUrl)
        self.recentEventIds = try? values.decode([Int].self, forKey: .recentEventIds)
        
        var parsedDate: Date?
        if let dateString = try? values.decode(String.self, forKey: .createdAt) {
            if let date = try? UserDTO.dateFormatter.parse(dateString) {
                parsedDate = date
            }
        }
        self.createdAt = parsedDate
        
        if let dateString = try? values.decode(String.self, forKey: .lastUpdated) {
            if let date = try? UserDTO.dateFormatter.parse(dateString) {
                parsedDate = date
            }
        }
        self.lastUpdated = parsedDate
        
        if let dateString = try? values.decode(String.self, forKey: .createdAt) {
            if let date = try? UserDTO.dateFormatter.parse(dateString) {
                parsedDate = date
            }
        }
        
        self.role = try? values.decode(RoleDTO.self, forKey: .role)
        self.roleId = try? values.decode(String.self, forKey: .roleId)
        self.enabled = (try? values.decode(Bool.self, forKey: .enabled)) ?? true
        self.active = try? values.decode(Bool.self, forKey: .active)
    }
}

public extension UserDTO {
    
    static func arrayFrom(jsonObject: [[AnyHashable: Any?]]) throws -> [UserDTO] {
        let decoder = JSONDecoder()
        return try decoder.decode([UserDTO].self, from: JSONSerialization.data(withJSONObject: jsonObject, options: []))
    }
}
