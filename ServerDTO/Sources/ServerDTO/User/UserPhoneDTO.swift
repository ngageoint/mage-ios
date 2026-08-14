//
//  UserPhoneDTO.swift
//  MAGE
//
//  Created by Daniel Barela on 7/17/26.
//  Copyright © 2026 National Geospatial Intelligence Agency. All rights reserved.
//


public struct UserPhoneDTO: Codable, Sendable {
    public init(number: String? = nil) {
        self.number = number
    }
    
    public let number: String?
}
