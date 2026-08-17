//
//  UserImporter.swift
//  User
//
//

import ServerDTO
import CoreData

public protocol UserImporter: Sendable {
    func importUser(
        _ dto: UserDTO,
        context: NSManagedObjectContext
    ) throws -> UserModel?
}
