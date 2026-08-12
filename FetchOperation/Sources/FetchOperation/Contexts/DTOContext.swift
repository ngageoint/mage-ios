//
//  DTOContext.swift
//  FetchOperation
//
//

import Foundation

public protocol DTOContext: Sendable {
    
    associatedtype DTO: Decodable & Sendable
    
    var dto: [DTO] { get set }
}
