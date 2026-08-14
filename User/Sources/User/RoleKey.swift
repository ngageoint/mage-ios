//
//  RoleKey.swift
//  User
//
//  Created by Daniel Barela on 8/5/26.
//


public enum RoleKey : String {
    case id
    case remoteId
    case permissions
    
    public var key: String {
        return self.rawValue;
    }
}
