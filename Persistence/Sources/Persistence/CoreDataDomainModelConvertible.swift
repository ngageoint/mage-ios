// 
//     
//  CoreDataDomainModelConvertible.swift
//  Persistence
//
// 

import CoreData

public protocol CoreDataDomainModelConvertible: Sendable {
    associatedtype Entity: NSManagedObject
    init(from entity: Entity)
}
