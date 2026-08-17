//
//  MapSearchType.swift
//  ServerDTO
//
//


import Foundation

public enum MapSearchType: Int32, Sendable {
    case none
    case native
    case nominatim
    
    var serverValue: String {
        switch self {
        case .native: return "NATIVE"
        case .nominatim: return "NOMINATIM"
        default: return "NONE"
        }
    }
    
    init(_ serverValue: String) {
        switch serverValue {
        case "NATIVE": self = .native
        case "NOMINATIM": self = .nominatim
        default: self = .none
        }
    }
}
