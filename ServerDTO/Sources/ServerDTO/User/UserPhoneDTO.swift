//
//  UserPhoneDTO.swift
//  MAGE
//


public struct UserPhoneDTO: Codable, Sendable {
    public init(number: String? = nil) {
        self.number = number
    }
    
    public let number: String?
}
