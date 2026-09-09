//
//  EventID.swift
//  MAGE
//
//


import Foundation

public struct ID<Tag>: Hashable, Codable, Sendable where Tag: Sendable {
    public let rawValue: NSNumber
    
    public init(_ rawValue: NSNumber) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: Int) {
        self.rawValue = NSNumber(value: rawValue)
    }
    
    public init(_ rawValue: Int64) {
        self.rawValue = NSNumber(value: rawValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        self.init(NSNumber(value: value))
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.intValue)
    }
}

public struct StringID<Tag>: Hashable, Codable, Sendable where Tag: Sendable {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(value)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct EventID: Hashable, Sendable, CustomStringConvertible, Codable {
    public var description: String {
        "EventID: \(rawValue)"
    }
    
    public let rawValue: NSNumber
    
    public init(_ rawValue: NSNumber) {
        self.rawValue = rawValue
    }
    
    public var intValue: Int {
        rawValue.intValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Int.self)
        self.init(NSNumber(value: value))
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.intValue)
    }
}

public enum LayerIDTag: Sendable {}
public enum StaticLayerFeatureIDTag: Sendable {}

public typealias TeamID = String
public typealias UserID = String
public typealias LayerID = ID<LayerIDTag>
public typealias StaticLayerFeatureID = StringID<StaticLayerFeatureIDTag>
public typealias FeedID = String
public typealias FormID = NSNumber
