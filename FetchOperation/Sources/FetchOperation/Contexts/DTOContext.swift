//
//  DTOContext.swift
//  FetchOperation
//
//  Created by Daniel Barela on 7/22/26.
//

import Foundation

public protocol DTOContext: Sendable {
    
    associatedtype DTO: Decodable & Sendable
    
    var dto: [DTO] { get set }
}
