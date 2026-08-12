//
//  EventID.swift
//  MAGE
//
//  Created by Daniel Barela on 7/17/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//


import Foundation

public struct EventID: Hashable, Sendable, CustomStringConvertible, Decodable {
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
}

public typealias TeamID = String
public typealias UserID = String
public typealias LayerID = NSNumber
public typealias FeedID = String
public typealias FormID = NSNumber
