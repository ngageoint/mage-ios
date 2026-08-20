//
//  LocationKey.swift
//  Location
//
//


public enum LocationKey : String {
    
    case id
    case type
    case eventId
    case properties
    case timestamp
    case geometry
    case user
    
    public var key : String {
        return self.rawValue
    }
}
