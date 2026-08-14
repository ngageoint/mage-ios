//
//  PermissionsKey.swift
//  User
//
//  Created by Daniel Barela on 8/5/26.
//


public enum PermissionsKey: String {
    case permissions
    
    case update
    case DELETE_OBSERVATION
    case UPDATE_EVENT
    case UPDATE_OBSERVATION_ALL
    case UPDATE_OBSERVATION_EVENT
    case CREATE_OBSERVATION
    
    public var key: String {
        return self.rawValue
    }
}
