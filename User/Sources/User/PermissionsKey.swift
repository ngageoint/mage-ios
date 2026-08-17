//
//  PermissionsKey.swift
//  User
//
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
