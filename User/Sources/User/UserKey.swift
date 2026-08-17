//
//  UserKey.swift
//  User
//
//


public enum UserKey : String {
    case remoteId
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
    case locations
    
    public var key: String {
        return self.rawValue
    }
}
