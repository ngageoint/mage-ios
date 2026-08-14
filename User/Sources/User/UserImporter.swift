//
//  UserImporter.swift
//  User
//
//  Created by Daniel Barela on 8/4/26.
//

import ServerDTO
import CoreData

public protocol UserImporter: Sendable {
    func importUser(
        _ dto: UserDTO,
        context: NSManagedObjectContext
    ) throws -> UserModel?
}
