//
//  UserIconDTO.swift
//  MAGE
//
//  Created by Daniel Barela on 7/17/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//


public struct UserIconDTO: Codable, Sendable {
    public init(text: String? = nil, color: String? = nil, contentType: String? = nil, size: Int? = nil, type: String? = nil) {
        self.text = text
        self.color = color
        self.contentType = contentType
        self.size = size
        self.type = type
    }
    
    public let text: String?
    public let color: String?
    public let contentType: String?
    public let size: Int?
    public let type: String?
}
