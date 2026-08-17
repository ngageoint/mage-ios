//
//  RoleKey.swift
//  User
//
//


public enum RoleKey : String {
    case id
    case remoteId
    case permissions
    
    public var key: String {
        return self.rawValue;
    }
}
